import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/features/security/data/repositories/security_repository_impl.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrefsSecurityRepository> makeRepo([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return PrefsSecurityRepository(await SharedPreferences.getInstance());
  }

  test('returns defaults when nothing is stored', () async {
    final repository = await makeRepo();

    final settings = await repository.load();

    expect(settings.appLock, isFalse);
    expect(settings.lockTimeout, LockTimeout.immediately);
    expect(settings.blockScreenshots, isFalse);
    expect(settings.pauseHistory, isFalse);
  });

  test('round-trips a saved snapshot', () async {
    final repository = await makeRepo();
    const settings = SecuritySettings(
      appLock: true,
      lockTimeout: LockTimeout.after15Minutes,
      blockScreenshots: true,
      pauseHistory: true,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('falls back to immediately for an unknown timeout name', () async {
    final repository = await makeRepo({'security.lock_timeout': 'whenever'});

    expect((await repository.load()).lockTimeout, LockTimeout.immediately);
  });
}
