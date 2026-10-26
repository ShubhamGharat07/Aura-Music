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

  /// Copies with overrides.
  AppSettings copyWith({
    String? glassOverride,
    bool? dynamicColor,
    bool? amoled,
    double? playbackSpeed,
    bool? skipSilence,
    bool clearGlass = false,
  }) {
    return AppSettings(
      glassOverride: clearGlass ? null : (glassOverride ?? this.glassOverride),
      dynamicColor: dynamicColor ?? this.dynamicColor,
      amoled: amoled ?? this.amoled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      skipSilence: skipSilence ?? this.skipSilence,
    );
  }

  @override
  List<Object?> get props => [
    glassOverride,
    dynamicColor,
    amoled,
    playbackSpeed,
    skipSilence,
  ];
}
