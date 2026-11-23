import 'package:equatable/equatable.dart';

/// Persisted settings entity (domain, pure Dart).

/// Snapshot of user settings.
final class AppSettings extends Equatable {
  /// Creates settings.
  const AppSettings({
    this.glassOverride,
    this.dynamicColor = true,
    this.amoled = false,
    this.playbackSpeed = 1.0,
    this.skipSilence = false,
    this.audioNormalization = true,
    this.equalizerEnabled = true,
    this.equalizerPreset = 'flat',
    this.equalizerBands = const <double>[0.0, 0.0, 0.0, 0.0, 0.0],
    this.smartAudioCache = true,
    this.maxCacheSizeMb = 512,
  });

  /// Creates defaults.
  const AppSettings.defaults() : this();

  /// Glass tier override name (`high`/`mid`/`low`/null = Auto).
  final String? glassOverride;

  /// Dynamic colour from album art.
  final bool dynamicColor;

  /// AMOLED pure-black theme.
  final bool amoled;

  /// Playback rate (0.75-1.5, PRD S18).
  final double playbackSpeed;

  /// Skip silent passages while playing (Android / iOS).
  final bool skipSilence;

  /// Normalizes track loudness to standard level (-14 LUFS).
  final bool audioNormalization;

  /// Master switch for the on-device Equalizer.
  final bool equalizerEnabled;

  /// Active equalizer preset name ('flat', 'bass_boost', 'vocals', etc.).
  final String equalizerPreset;

  /// 5-band EQ gain levels in dB (-12.0 to +12.0).
  final List<double> equalizerBands;

  /// Automatically caches streamed songs to disk for zero-internet instant replay.
  final bool smartAudioCache;

  /// Maximum disk space allocated for audio caching in megabytes.
  final int maxCacheSizeMb;

  /// Copies with overrides.
  AppSettings copyWith({
    String? glassOverride,
    bool? dynamicColor,
    bool? amoled,
    double? playbackSpeed,
    bool? skipSilence,
    bool? audioNormalization,
    bool? equalizerEnabled,
    String? equalizerPreset,
    List<double>? equalizerBands,
    bool? smartAudioCache,
    int? maxCacheSizeMb,
    bool clearGlass = false,
  }) {
    return AppSettings(
      glassOverride: clearGlass ? null : (glassOverride ?? this.glassOverride),
      dynamicColor: dynamicColor ?? this.dynamicColor,
      amoled: amoled ?? this.amoled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      skipSilence: skipSilence ?? this.skipSilence,
      audioNormalization: audioNormalization ?? this.audioNormalization,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      equalizerBands: equalizerBands ?? this.equalizerBands,
      smartAudioCache: smartAudioCache ?? this.smartAudioCache,
      maxCacheSizeMb: maxCacheSizeMb ?? this.maxCacheSizeMb,
    );
  }

  @override
  List<Object?> get props => [
    glassOverride,
    dynamicColor,
    amoled,
    playbackSpeed,
    skipSilence,
    audioNormalization,
    equalizerEnabled,
    equalizerPreset,
    equalizerBands,
    smartAudioCache,
    maxCacheSizeMb,
  ];
}
