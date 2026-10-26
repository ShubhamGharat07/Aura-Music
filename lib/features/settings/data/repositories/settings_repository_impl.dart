import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/features/settings/domain/entities/app_settings.dart';
import 'package:aura_music/features/settings/domain/repositories/settings_repository.dart';

/// SharedPreferences-backed settings store (data layer).

/// Prefs implementation of [SettingsRepository].
final class PrefsSettingsRepository implements SettingsRepository {
  /// Creates the repository.
  PrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kGlass = 'appearance.glass';
  static const _kDynamic = 'appearance.dynamic_color';
  static const _kAmoled = 'appearance.amoled';
  static const _kSpeed = 'audio.speed';
  static const _kSkipSilence = 'audio.skip_silence';

  static const double _minSpeed = 0.75;
  static const double _maxSpeed = 1.5;

  @override
  Future<AppSettings> load() async => AppSettings(
    glassOverride: _prefs.getString(_kGlass),
    dynamicColor: _prefs.getBool(_kDynamic) ?? true,
    amoled: _prefs.getBool(_kAmoled) ?? false,
    playbackSpeed: (_prefs.getDouble(_kSpeed) ?? 1.0)
        .clamp(_minSpeed, _maxSpeed)
        .toDouble(),
    skipSilence: _prefs.getBool(_kSkipSilence) ?? false,
  );

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      if (settings.glassOverride == null)
        _prefs.remove(_kGlass)
      else
        _prefs.setString(_kGlass, settings.glassOverride!),
      _prefs.setBool(_kDynamic, settings.dynamicColor),
      _prefs.setBool(_kAmoled, settings.amoled),
      _prefs.setDouble(_kSpeed, settings.playbackSpeed),
      _prefs.setBool(_kSkipSilence, settings.skipSilence),
    ]);
  }
}
