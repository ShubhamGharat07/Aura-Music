import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/services/biometric_service.dart';
import 'package:aura_music/core/services/screen_security_service.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';
import 'package:aura_music/features/security/domain/usecases/load_security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/update_security_settings.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';

final class _MockLocalAuth extends Mock implements LocalAuthentication {}

final class _FakeSecurityRepository implements SecurityRepository {
  SecuritySettings settings = const SecuritySettings.defaults();
  int saves = 0;

  @override
  Future<SecuritySettings> load() async => settings;

  @override
  Future<void> save(SecuritySettings value) async {
    settings = value;
    saves++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('aura/screen');

  late _MockLocalAuth auth;
  late _FakeSecurityRepository repository;
  late List<MethodCall> calls;

  setUp(() {
    auth = _MockLocalAuth();
    repository = _FakeSecurityRepository();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
    when(
      () => auth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        sensitiveTransaction: any(named: 'sensitiveTransaction'),
      ),
    ).thenAnswer((_) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  SecurityCubit makeCubit() {
    final cubit = SecurityCubit(
      LoadSecuritySettings(repository),
      UpdateSecuritySettings(repository),
      BiometricService(auth: auth),
      const ScreenSecurityService(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('load applies FLAG_SECURE and locks when the app lock is on', () async {
    repository.settings = const SecuritySettings(
      appLock: true,
      blockScreenshots: true,
    );
    final cubit = makeCubit();

    await cubit.load();

    expect(cubit.state.settings.appLock, isTrue);
    expect(cubit.state.locked, isTrue);
    expect(calls.single.method, 'setSecure');
    expect(calls.single.arguments, isTrue);
  });

  test('load leaves the app unlocked by default', () async {
    final cubit = makeCubit();

    await cubit.load();

    expect(cubit.state.locked, isFalse);
    expect(calls.single.arguments, isFalse);
  });

  test('setAppLock refuses when the device cannot authenticate', () async {
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);
    final cubit = makeCubit();

    final ok = await cubit.setAppLock(true);

    expect(ok, isFalse);
    expect(cubit.state.settings.appLock, isFalse);
    expect(repository.saves, 0);
  });

  test('setAppLock persists and locks immediately', () async {
    final cubit = makeCubit();

    final ok = await cubit.setAppLock(true);

    expect(ok, isTrue);
    expect(repository.settings.appLock, isTrue);
    expect(cubit.state.locked, isTrue);
  });

  test('unlock clears the lock on success and keeps it on failure', () async {
    repository.settings = const SecuritySettings(appLock: true);
    final cubit = makeCubit();
    await cubit.load();

    await cubit.unlock();
    expect(cubit.state.locked, isFalse);

    when(
      () => auth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        sensitiveTransaction: any(named: 'sensitiveTransaction'),
      ),
    ).thenAnswer((_) async => false);
    cubit.lock();
    await cubit.unlock();
    expect(cubit.state.locked, isTrue);
  });

  test('lock is a no-op while the app lock is disabled', () async {
    final cubit = makeCubit();
    await cubit.load();

    cubit.lock();

    expect(cubit.state.locked, isFalse);
  });

  test('setBlockScreenshots toggles the secure flag and persists', () async {
    final cubit = makeCubit();
    await cubit.load();
    calls.clear();

    await cubit.setBlockScreenshots(true);

    expect(repository.settings.blockScreenshots, isTrue);
    expect(calls.single.arguments, isTrue);
  });

  test('setPauseHistory persists without touching the screen flag', () async {
    final cubit = makeCubit();
    await cubit.load();
    calls.clear();

    await cubit.setPauseHistory(true);

    expect(repository.settings.pauseHistory, isTrue);
    expect(calls, isEmpty);
  });

  test('setLockTimeout persists the grace period', () async {
    final cubit = makeCubit();
    await cubit.load();

    await cubit.setLockTimeout(LockTimeout.after5Minutes);

    expect(repository.settings.lockTimeout, LockTimeout.after5Minutes);
  });

  test('load falls back to defaults when the repository throws', () async {
    final failing = _ThrowingRepository();
    final cubit = SecurityCubit(
      LoadSecuritySettings(failing),
      UpdateSecuritySettings(failing),
      BiometricService(auth: auth),
      const ScreenSecurityService(),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.settings, const SecuritySettings.defaults());
  });
}

final class _ThrowingRepository implements SecurityRepository {
  @override
  Future<SecuritySettings> load() async => throw Exception('boom');

  @override
  Future<void> save(SecuritySettings settings) async {}
}
