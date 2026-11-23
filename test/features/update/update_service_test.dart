import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/services/update_downloads.dart';
import 'package:aura_music/core/services/update_manifest.dart';
import 'package:aura_music/core/services/update_service.dart';

class _MockDio extends Mock implements Dio {}

const _tag = 'v1.0.0+2';
const _root =
    'https://github.com/${AppConstants.githubOwner}/${AppConstants.githubRepo}/releases/download/$_tag';
const _content = 'test archive bytes';
final _digest = sha256.convert(utf8.encode(_content)).toString();

Map<String, Object> asset(String abi, {int? versionCode}) => {
  'name': 'aura-$abi.apk',
  'abi': abi,
  'size': _content.length,
  'sha256': _digest,
  'versionCode': ?versionCode,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _MockDio dio;
  late SharedPreferences prefs;

  UpdateService service({
    String build = '1',
    List<String> abis = const ['arm64-v8a'],
  }) => UpdateService(
    dio,
    prefs: prefs,
    packageInfo: () async => PackageInfo(
      appName: 'Aura Music',
      packageName: 'com.example.aura_music',
      version: '1.0.0',
      buildNumber: build,
    ),
    supportedAbis: () async => abis,
    isAndroid: () => true,
  );

  setUp(() async {
    dio = _MockDio();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  void stubRelease(
    List<Map<String, Object>> assets, {
    String? badApkUrl,
    int manifestStatus = 200,
    Map<String, List<String>>? manifestHeaders,
    bool includeApk = true,
  }) {
    final manifest = jsonEncode({
      'versionCode': 2,
      'versionName': '1.0.0',
      'assets': assets,
    });
    when(
      () => dio.get<Map<String, dynamic>>(
        AppConstants.githubReleasesUrl,
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'tag_name': _tag,
          'name': 'Aura Update',
          'body': 'Release notes',
          'assets': [
            {
              'name': 'update.json',
              'size': utf8.encode(manifest).length,
              'browser_download_url': '$_root/update.json',
            },
            if (includeApk)
              for (final item in assets)
                {
                  'name': item['name'],
                  'size': item['size'],
                  'browser_download_url': badApkUrl ?? '$_root/${item['name']}',
                },
          ],
        },
      ),
    );
    when(
      () => dio.get<ResponseBody>(
        '$_root/update.json',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: manifestStatus,
        headers: Headers.fromMap(manifestHeaders ?? {}),
        data: ResponseBody.fromString(manifest, manifestStatus),
      ),
    );
  }

  test(
    'offers a same-name upgrade when the selected APK build code is higher',
    () async {
      stubRelease([asset('arm64-v8a', versionCode: 2002), asset('universal')]);
      final result = await service(build: '2001').check();
      expect(result!.isUpdateAvailable, isTrue);
      expect(result.latestVersion, '1.0.0');
      expect(result.versionCode, 2002);
      expect(result.asset!.abi, 'arm64-v8a');
      expect(result.releaseNotes, 'Release notes');
    },
  );

  test('uses device ABI order and never selects an incompatible APK', () async {
    stubRelease([asset('arm64-v8a'), asset('x86_64')]);
    final preferred = await service(abis: ['x86_64', 'arm64-v8a']).check();
    expect(preferred!.asset!.abi, 'x86_64');
    final unsupported = await service(abis: ['x86']).check();
    expect(unsupported!.isUpdateAvailable, isFalse);
    expect(unsupported.unavailableReason, isNotNull);
  });

  test(
    'falls back to a declared universal APK and rejects a downgrade',
    () async {
      stubRelease([asset('arm64-v8a'), asset('universal')]);
      final universal = await service(abis: ['x86']).check();
      expect(universal!.asset!.abi, 'universal');
      final old = await service(build: '3').check();
      expect(old!.isUpdateAvailable, isFalse);
      expect(old.unavailableReason, isNull);
    },
  );

  test('does not offer an APK missing from the actual release', () async {
    stubRelease([asset('universal')], includeApk: false);
    final result = await service().check();
    expect(result!.isUpdateAvailable, isFalse);
    expect(result.unavailableReason, isNotNull);
  });

  test('rejects an asset URL outside the configured release', () async {
    stubRelease([
      asset('universal'),
    ], badApkUrl: 'https://example.org/file.apk');
    final result = await service().check();
    expect(result!.isUpdateAvailable, isFalse);
  });

  test('rejects an untrusted manifest redirect', () async {
    stubRelease(
      [asset('universal')],
      manifestStatus: 302,
      manifestHeaders: {
        'location': ['https://example.org/update.json'],
      },
    );
    expect(await service().check(), isNull);
    verifyNever(
      () => dio.get<ResponseBody>(
        'https://example.org/update.json',
        options: any(named: 'options'),
      ),
    );
  });

  test(
    'startup throttles repeat checks and restores the cached release',
    () async {
      stubRelease([asset('universal')]);
      await service().checkAndNotify();
      final reopened = service();
      await reopened.checkAndNotify();
      expect(reopened.latest.value!.isUpdateAvailable, isTrue);
      verify(
        () => dio.get<Map<String, dynamic>>(
          AppConstants.githubReleasesUrl,
          options: any(named: 'options'),
        ),
      ).called(1);
      final updated = service(build: '2');
      await updated.restore();
      expect(updated.latest.value, isNull);
    },
  );

  test('concurrent manual checks share one release request', () async {
    stubRelease([asset('universal')]);
    final updater = service();
    final checks = await Future.wait([updater.check(), updater.check()]);
    expect(checks.first, same(checks.last));
    verify(
      () => dio.get<Map<String, dynamic>>(
        AppConstants.githubReleasesUrl,
        options: any(named: 'options'),
      ),
    ).called(1);
  });

  test('fails closed on invalid manifest metadata', () async {
    stubRelease([
      {...asset('universal'), 'sha256': 'missing'},
    ]);
    expect(await service().check(), isNull);
  });

  test('returns no result on a network error', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        AppConstants.githubReleasesUrl,
        options: any(named: 'options'),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '')));
    expect(await service().check(), isNull);
  });

  test(
    'file integrity rejects truncated and same-length changed APKs',
    () async {
      final directory = await Directory.systemTemp.createTemp('aura-ota-test');
      addTearDown(() => directory.delete(recursive: true));
      final apk = File('${directory.path}/download.apk');
      final metadata = UpdateAsset.parse(asset('universal'));

      expect(await verifyUpdateApk(apk, metadata), isFalse);
      await apk.writeAsString('short');
      expect(await verifyUpdateApk(apk, metadata), isFalse);
      await apk.writeAsString('X${_content.substring(1)}');
      expect(await verifyUpdateApk(apk, metadata), isFalse);
      await apk.writeAsString(_content);
      expect(await verifyUpdateApk(apk, metadata), isTrue);
    },
  );
}
