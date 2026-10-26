import 'dart:async';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/usecases/save_playback_session.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';

/// Persists the playback session (PRD S06): a position snapshot every
/// [AppConstants.queueAutosaveInterval] while playing, plus an immediate write
/// on every state change (track change, queue edit, play/pause).
///
/// Kept out of [PlayerBloc] so the speed-critical transport code stays small;
/// the write itself is fire-and-forget.
final class PlayerSessionRecorder {
  /// Creates the recorder.
  PlayerSessionRecorder({
    required SavePlaybackSession save,
    required PlayerState Function() state,
    required Duration Function() position,
  }) : _save = save,
       _state = state,
       _position = position;

  final SavePlaybackSession _save;
  final PlayerState Function() _state;
  final Duration Function() _position;

  Timer? _timer;
  Duration _savedPosition = Duration.zero;

  /// Starts the periodic position snapshot (no-op when already running).
  void start() {
    _timer ??= Timer.periodic(
      AppConstants.queueAutosaveInterval,
      (_) => unawaited(_onTick()),
    );
  }

  /// Writes the session right away.
  Future<void> flush() => _write().catchError((Object _) {});

  Future<void> _onTick() async {
    if (!_state().isPlaying) return;
    if (_position() == _savedPosition) return;
    await _write().catchError((Object _) {});
  }

  Future<void> _write() async {
    final state = _state();
    if (state.currentTrack == null) return;
    final position = _position();
    _savedPosition = position;
    await _save(
      PlaybackSession(
        queue: state.queue,
        index: state.currentIndex,
        position: position,
        shuffle: state.shuffle,
        repeat: state.repeat,
      ),
    );
  }

  /// Cancels the snapshot timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
