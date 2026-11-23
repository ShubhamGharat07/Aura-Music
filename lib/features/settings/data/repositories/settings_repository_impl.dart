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
  static const _kAudioNormalization = 'audio.normalization';
  static const _kEqualizerEnabled = 'audio.equalizer_enabled';
  static const _kEqualizerPreset = 'audio.equalizer_preset';
  static const _kEqualizerBands = 'audio.equalizer_bands';
  static const _kSmartAudioCache = 'audio.smart_audio_cache';
  static const _kMaxCacheSizeMb = 'audio.max_cache_size_mb';

  static const double _minSpeed = 0.75;
  static const double _maxSpeed = 1.5;

  @override
  Future<AppSettings> load() async {
    final bandsRaw = _prefs.getStringList(_kEqualizerBands);
    final bands = bandsRaw != null && bandsRaw.length == 5
        ? bandsRaw.map((b) => double.tryParse(b) ?? 0.0).toList()
        : const <double>[0.0, 0.0, 0.0, 0.0, 0.0];

    return AppSettings(
      glassOverride: _prefs.getString(_kGlass),
      dynamicColor: _prefs.getBool(_kDynamic) ?? true,
      amoled: _prefs.getBool(_kAmoled) ?? false,
      playbackSpeed: (_prefs.getDouble(_kSpeed) ?? 1.0)
          .clamp(_minSpeed, _maxSpeed)
          .toDouble(),
      skipSilence: _prefs.getBool(_kSkipSilence) ?? false,
      audioNormalization: _prefs.getBool(_kAudioNormalization) ?? true,
      equalizerEnabled: _prefs.getBool(_kEqualizerEnabled) ?? true,
      equalizerPreset: _prefs.getString(_kEqualizerPreset) ?? 'flat',
      equalizerBands: bands,
      smartAudioCache: _prefs.getBool(_kSmartAudioCache) ?? true,
      maxCacheSizeMb: _prefs.getInt(_kMaxCacheSizeMb) ?? 512,
    );
  }

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
      _prefs.setBool(_kAudioNormalization, settings.audioNormalization),
      _prefs.setBool(_kEqualizerEnabled, settings.equalizerEnabled),
      _prefs.setString(_kEqualizerPreset, settings.equalizerPreset),
      _prefs.setStringList(
        _kEqualizerBands,
        settings.equalizerBands.map((b) => b.toStringAsFixed(1)).toList(),
      ),
      _prefs.setBool(_kSmartAudioCache, settings.smartAudioCache),
      _prefs.setInt(_kMaxCacheSizeMb, settings.maxCacheSizeMb),
    ]);
  }
}
