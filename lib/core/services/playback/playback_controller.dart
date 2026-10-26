import 'package:flutter/foundation.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Playback abstraction (PRD 4.1). Production wires
// `JustAudioPlaybackController` (just_audio + audio_service media session);
// `FakePlaybackController` keeps BLoC/UI tests free of native audio.
//
// Position / buffered position are exposed as [ValueListenable] (>=10 Hz)
// so widgets rebuild surgically instead of the whole screen.

/// Resolves a local file path for offline playback; null streams remotely.
typedef LocalFileResolver = Future<String?> Function(String trackId);

/// Transport + position contract used by [PlayerBloc] and the UI.
abstract class PlaybackController {
  /// Current playback position (high frequency).
  ValueListenable<Duration> get position;

  /// Buffered position (high frequency).
  ValueListenable<Duration> get buffered;

  /// Duration of the loaded track.
  Duration get duration;

  /// Whether audio is currently playing.
  bool get isPlaying;

  /// Reactive transport status (playing / buffering / paused / idle). Never
  /// emits [PlaybackStatus.error]; resolve failures are surfaced by the BLoC.
  Stream<PlaybackStatus> get statusStream;

  /// Fatal engine errors (decoder, network source, audio session). The BLoC
  /// turns these into [PlaybackStatus.error] and the next play tap reloads.
  Stream<String> get errorStream;

  /// Fires when a track reaches its end.
  Stream<void> get onCompleted;

  /// Loads [track], resuming at [startAt]. When [autoPlay] is false the track
  /// is left loaded but paused (session restore, PRD S06).
  Future<void> load(
    Track track, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  });

  /// Starts / resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Seeks to [position].
  Future<void> seek(Duration position);

  /// Changes the playback rate (1.0 = normal).
  Future<void> setSpeed(double speed);

  /// Enables / disables skipping silent passages.
  Future<void> setSkipSilence(bool enabled);

  /// Releases resources.
  Future<void> dispose();
}
