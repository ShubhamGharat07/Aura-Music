import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';

/// SharedPreferences-backed security store (data layer).

/// Prefs implementation of [SecurityRepository].
final class PrefsSecurityRepository implements SecurityRepository {
  /// Creates the repository.
  PrefsSecurityRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kAppLock = 'security.app_lock';
  static const _kLockTimeout = 'security.lock_timeout';
  static const _kBlockScreenshots = 'security.block_screenshots';
  static const _kPauseHistory = 'security.pause_history';

  @override
  Future<SecuritySettings> load() async => SecuritySettings(
    appLock: _prefs.getBool(_kAppLock) ?? false,
    lockTimeout: _timeoutFrom(_prefs.getString(_kLockTimeout)),
    blockScreenshots: _prefs.getBool(_kBlockScreenshots) ?? false,
    pauseHistory: _prefs.getBool(_kPauseHistory) ?? false,
  );

  @override
  Future<void> save(SecuritySettings settings) async {
    await _prefs.setBool(_kAppLock, settings.appLock);
    await _prefs.setString(_kLockTimeout, settings.lockTimeout.name);
    await _prefs.setBool(_kBlockScreenshots, settings.blockScreenshots);
    await _prefs.setBool(_kPauseHistory, settings.pauseHistory);
  }

  LockTimeout _timeoutFrom(String? name) => LockTimeout.values.firstWhere(
    (value) => value.name == name,
    orElse: () => LockTimeout.immediately,
  );
}
