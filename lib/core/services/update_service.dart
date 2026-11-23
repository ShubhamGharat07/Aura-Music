import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/services/app_notification_service.dart';
import 'package:aura_music/core/services/update_manifest.dart';

/// Release metadata and the compatible APK, if one is available.
final class UpdateInfo {
  const UpdateInfo._({
    required this.latestVersion,
    required this.versionCode,
    required this.releaseTitle,
    this.releaseNotes,
    this.asset,
    this.downloadUri,
    this.unavailableReason,
  });

  final String latestVersion;
  final int versionCode;
  final String releaseTitle;
  final String? releaseNotes;
  final UpdateAsset? asset;
  final Uri? downloadUri;
  final String? unavailableReason;

  bool get isUpdateAvailable => asset != null && downloadUri != null;
}

/// Checks Aura's stable GitHub channel and remembers the result for Settings.
final class UpdateService {
  UpdateService(
    this._dio, {
    this.notifications,
    this.prefs,
    Future<PackageInfo> Function()? packageInfo,
    Future<List<String>> Function()? supportedAbis,
    bool Function()? isAndroid,
  }) : _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _supportedAbis = supportedAbis ?? _androidAbis,
       _isAndroid =
           isAndroid ??
           (() => defaultTargetPlatform == TargetPlatform.android && !kIsWeb);

  final Dio _dio;
  final AppNotificationService? notifications;
  final SharedPreferences? prefs;
  final Future<PackageInfo> Function() _packageInfo;
  final Future<List<String>> Function() _supportedAbis;
  final bool Function() _isAndroid;

  final latest = ValueNotifier<UpdateInfo?>(null);
  Future<UpdateInfo?>? _checking;
  Future<void>? _automaticCheck;
  static const _cachedUpdate = 'ota_cached_update';
  static const _autoEnabled = 'ota_automatic_checks';
  static const _alertsEnabled = 'ota_update_alerts';
  static const _lastSuccess = 'ota_last_manifest_check';
  static const _lastAttempt = 'ota_last_attempt';
  static const _notified = 'ota_notified_version_code';
  static const _skipped = 'ota_skipped_version_code';
  static const _maxManifestSize = 64 * 1024;

  bool get supported => _isAndroid();
  bool get automaticChecks => prefs?.getBool(_autoEnabled) ?? true;
  bool get updateAlerts => prefs?.getBool(_alertsEnabled) ?? true;
  bool isSkipped(UpdateInfo update) =>
      prefs?.getInt(_skipped) == update.versionCode;

  Future<void> setAutomaticChecks(bool value) async {
    await prefs?.setBool(_autoEnabled, value);
  }

  Future<void> setUpdateAlerts(bool value) async {
    await prefs?.setBool(_alertsEnabled, value);
    if (value) {
      await _notify(latest.value);
    } else {
      await notifications?.clearUpdateAvailable();
    }
  }

  Future<void> skip(UpdateInfo update) async {
    await prefs?.setInt(_skipped, update.versionCode);
    await notifications?.clearUpdateAvailable();
  }

  /// Uses cached metadata to reconnect to a previous download offline.
  Future<void> restore() async {
    if (!supported || latest.value != null || _checking != null) return;
    final raw = prefs?.getString(_cachedUpdate);
    if (raw == null) return;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      final code = saved['versionCode'] as int;
      final installed = await _installedVersionCode();
      if (code <= installed) {
        await prefs?.remove(_cachedUpdate);
        await notifications?.clearUpdateAvailable();
        return;
      }
      final tag = saved['tag'] as String;
      final asset = UpdateAsset.parse(saved['asset']);
      final uri = _releaseUri(saved['url'], tag, asset.name);
      if (uri == null) throw const FormatException('Invalid cached URL');
      if (latest.value != null || _checking != null) return;
      latest.value = UpdateInfo._(
        latestVersion: tag.substring(1).split('+').first,
        versionCode: code,
        releaseTitle: saved['title'] as String,
        releaseNotes: saved['notes'] as String?,
        asset: asset,
        downloadUri: uri,
      );
    } on Object {
      await prefs?.remove(_cachedUpdate);
    }
  }

  /// Throttled startup check. A version is announced once per installation.
  Future<void> checkAndNotify() => _automaticCheck ??= _checkAndNotify()
      .catchError((Object _) {})
      .whenComplete(() => _automaticCheck = null);

  Future<void> _checkAndNotify() async {
    await restore();
    if (!supported || !automaticChecks) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSuccess = prefs?.getInt(_lastSuccess) ?? 0;
    final lastAttempt = prefs?.getInt(_lastAttempt) ?? 0;
    if (now - lastSuccess < AppConstants.updateCheckInterval.inMilliseconds ||
        now - lastAttempt < const Duration(minutes: 15).inMilliseconds) {
      await _notify(latest.value);
      return;
    }
    await prefs?.setInt(_lastAttempt, now);
    final update = await check();
    if (update == null) return;
    await prefs?.setInt(_lastSuccess, now);
    await _notify(update);
  }

  Future<void> _notify(UpdateInfo? update) async {
    if (update == null ||
        !update.isUpdateAvailable ||
        !updateAlerts ||
        isSkipped(update) ||
        (prefs?.getInt(_notified) ?? 0) >= update.versionCode) {
      return;
    }
    final posted = await notifications?.showUpdateAvailable(
      version: update.latestVersion,
      releaseTitle: update.releaseTitle,
    );
    if (posted == true) await prefs?.setInt(_notified, update.versionCode);
  }

  /// Manual checks share an in-flight request and bypass the startup throttle.
  Future<UpdateInfo?> check() =>
      _checking ??= _check().whenComplete(() => _checking = null);

  Future<UpdateInfo?> _check() async {
    if (!supported) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConstants.githubReleasesUrl,
        options: Options(
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'AuraMusicApp',
          },
          followRedirects: false,
          receiveTimeout: AppConstants.shortTimeout,
        ),
      );
      final release = response.data;
      final tag = release?['tag_name'];
      final assets = release?['assets'];
      if (tag is! String ||
          !RegExp(r'^v\d+\.\d+\.\d+(?:\+\d+)?$').hasMatch(tag) ||
          assets is! List<dynamic> ||
          release?['draft'] == true ||
          release?['prerelease'] == true) {
        return null;
      }
      final entries = assets.whereType<Map<String, dynamic>>();
      final manifestFile = _findAsset(entries, 'update.json');
      final manifestUri = _releaseUri(
        manifestFile?['browser_download_url'],
        tag,
        'update.json',
      );
      final manifestSize = manifestFile?['size'];
      if (manifestUri == null ||
          manifestSize is! int ||
          manifestSize <= 0 ||
          manifestSize > _maxManifestSize) {
        return null;
      }
      final manifest = await _readManifest(manifestUri, manifestSize);
      if (tag.substring(1).split('+').first != manifest.versionName) {
        return null;
      }

      final installed = await _installedVersionCode();
      final urls = <String, Uri>{};
      for (final asset in manifest.assets) {
        final entry = _findAsset(entries, asset.name);
        if (entry?['size'] != asset.size) continue;
        final uri = _releaseUri(
          entry?['browser_download_url'],
          tag,
          asset.name,
        );
        if (uri != null) urls[asset.name] = uri;
      }
      final apk = manifest.select(
        await _supportedAbis(),
        matchesRelease: (asset) => urls.containsKey(asset.name),
      );
      final versionCode = apk == null
          ? manifest.versionCode
          : manifest.codeFor(apk);
      final uri = apk != null && versionCode > installed
          ? urls[apk.name]
          : null;
      final incompatible =
          apk == null &&
          manifest.assets.any((asset) => manifest.codeFor(asset) > installed);
      final title = release?['name'];
      final notes = release?['body'];
      final result = UpdateInfo._(
        latestVersion: manifest.versionName,
        versionCode: versionCode,
        releaseTitle: title is String && title.isNotEmpty ? title : tag,
        releaseNotes: notes is String ? notes : null,
        asset: uri == null ? null : apk,
        downloadUri: uri,
        unavailableReason: incompatible
            ? 'This release has no compatible verified APK for your device.'
            : null,
      );
      latest.value = result;
      if (apk != null && uri != null) {
        await prefs?.setString(
          _cachedUpdate,
          jsonEncode({
            'tag': tag,
            'versionCode': versionCode,
            'title': result.releaseTitle,
            'notes': result.releaseNotes,
            'asset': apk.toJson(),
            'url': uri.toString(),
          }),
        );
      } else {
        await prefs?.remove(_cachedUpdate);
        await notifications?.clearUpdateAvailable();
      }
      return result;
    } on Object catch (error) {
      if (kDebugMode) debugPrint('Update check failed: $error');
      return null;
    }
  }

  Future<UpdateManifest> _readManifest(Uri initial, int size) async {
    var uri = initial;
    for (var hop = 0; hop < 4; hop++) {
      final response = await _dio.get<ResponseBody>(
        uri.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          receiveTimeout: AppConstants.shortTimeout,
          validateStatus: (code) =>
              code == 200 || const {301, 302, 303, 307, 308}.contains(code),
        ),
      );
      final stream = response.data!.stream;
      if (response.statusCode == 200) {
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in stream) {
          if (bytes.length + chunk.length > size) {
            throw const FormatException('Update manifest too large');
          }
          bytes.add(chunk);
        }
        if (bytes.length != size) {
          throw const FormatException('Truncated update manifest');
        }
        return UpdateManifest.parse(
          jsonDecode(utf8.decode(bytes.takeBytes())) as Map<String, dynamic>,
        );
      }
      await stream.listen(null).cancel();
      final location = response.headers.value('location');
      if (location == null) break;
      uri = uri.resolve(location);
      if (!_isHttps(uri) ||
          !const {
            'release-assets.githubusercontent.com',
            'objects.githubusercontent.com',
            'github-releases.githubusercontent.com',
          }.contains(uri.host)) {
        break;
      }
    }
    throw const FormatException('Untrusted update manifest redirect');
  }

  Future<int> _installedVersionCode() async =>
      int.parse((await _packageInfo()).buildNumber);

  static Future<List<String>> _androidAbis() async =>
      (await DeviceInfoPlugin().androidInfo).supportedAbis;

  static Map<String, dynamic>? _findAsset(
    Iterable<Map<String, dynamic>> assets,
    String name,
  ) {
    final matches = assets
        .where((asset) => asset['name'] == name)
        .take(2)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  static bool _isHttps(Uri uri) =>
      uri.scheme == 'https' && uri.port == 443 && uri.userInfo.isEmpty;

  static Uri? _releaseUri(Object? raw, String tag, String name) {
    if (raw is! String) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !_isHttps(uri) ||
        uri.host != 'github.com' ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 6 ||
        segments[0].toLowerCase() != AppConstants.githubOwner.toLowerCase() ||
        segments[1].toLowerCase() != AppConstants.githubRepo.toLowerCase() ||
        !listEquals(segments.sublist(2), ['releases', 'download', tag, name])) {
      return null;
    }
    return uri;
  }
}
