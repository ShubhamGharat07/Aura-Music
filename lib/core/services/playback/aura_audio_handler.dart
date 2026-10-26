import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';

/// Media-session bridge for the system notification / lock screen (PRD F03).
///
/// [PlaybackController] stays the single transport owner: the handler only
/// mirrors its position/status into [playbackState] and forwards notification
/// taps back through the callbacks, so there is no second source of truth.
final class AuraAudioHandler extends BaseAudioHandler {
  /// Creates the handler.
  AuraAudioHandler({
    required ValueListenable<Duration> position,
    required ValueListenable<Duration> buffered,
    required Stream<PlaybackStatus> statusStream,
    required VoidCallback onPlay,
    required VoidCallback onPause,
    required VoidCallback onNext,
    required VoidCallback onPrevious,
    required VoidCallback onLike,
    required void Function(Duration position) onSeek,
  }) : _position = position,
       _buffered = buffered,
       _onPlay = onPlay,
       _onPause = onPause,
       _onNext = onNext,
       _onPrevious = onPrevious,
       _onLike = onLike,
       _onSeek = onSeek {
    _statusSub = statusStream.listen(_onStatus);
    _position.addListener(_onPosition);
    _emit();
  }

  final ValueListenable<Duration> _position;
  final ValueListenable<Duration> _buffered;
  final VoidCallback _onPlay;
  final VoidCallback _onPause;
  final VoidCallback _onNext;
  final VoidCallback _onPrevious;
  final VoidCallback _onLike;
  final void Function(Duration position) _onSeek;
  late final StreamSubscription<PlaybackStatus> _statusSub;

  /// Custom notification control id for the like toggle.
  static const String likeAction = 'like';

  bool _playing = false;
  bool _hasNext = false;
  bool _hasPrevious = false;
  bool _hasMedia = false;
  bool _liked = false;
  AudioProcessingState _processing = AudioProcessingState.idle;
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  /// Publishes the current track, skip availability and like state.
  void setNowPlaying(
    MediaItem item, {
    required bool hasNext,
    required bool hasPrevious,
    required bool liked,
  }) {
    _hasNext = hasNext;
    _hasPrevious = hasPrevious;
    _hasMedia = true;
    _liked = liked;
    mediaItem.add(item);
    _emit(force: true);
  }

  /// Clears the session when the queue is emptied.
  void clearNowPlaying() {
    mediaItem.add(null);
    _playing = false;
    _hasNext = false;
    _hasPrevious = false;
    _hasMedia = false;
    _liked = false;
    _processing = AudioProcessingState.idle;
    _emit(force: true);
  }

  @override
  Future<void> play() async => _onPlay();

  @override
  Future<void> pause() async => _onPause();

  @override
  Future<void> seek(Duration position) async => _onSeek(position);

  @override
  Future<void> skipToNext() async => _onNext();

  @override
  Future<void> skipToPrevious() async => _onPrevious();

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == likeAction) {
      _onLike();
      return;
    }
    await super.customAction(name, extras);
  }

  @override
  Future<void> stop() async {
    _onPause();
    await super.stop();
  }

  /// Releases the subscriptions (app shutdown / tests).
  Future<void> disposeHandler() async {
    _position.removeListener(_onPosition);
    await _statusSub.cancel();
  }

  void _onStatus(PlaybackStatus status) {
    _playing = status == PlaybackStatus.playing;
    _processing = switch (status) {
      PlaybackStatus.idle => AudioProcessingState.idle,
      PlaybackStatus.loading => AudioProcessingState.buffering,
      PlaybackStatus.playing => AudioProcessingState.ready,
      PlaybackStatus.paused => AudioProcessingState.ready,
      PlaybackStatus.error => AudioProcessingState.error,
    };
    _emit(force: true);
  }

  // The controller ticks at >= 10 Hz; the platform only needs progress about
  // once a second, so throttle unless something structural changed.
  void _onPosition() {
    if (!_playing) return;
    final now = DateTime.now();
    if (now.difference(_lastEmit) < const Duration(seconds: 1)) return;
    _emit();
  }

  void _emit({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastEmit) < const Duration(seconds: 1)) {
      return;
    }
    _lastEmit = now;
    playbackState.add(
      PlaybackState(
        controls: [
          if (_hasPrevious) MediaControl.skipToPrevious,
          if (_playing) MediaControl.pause else MediaControl.play,
          if (_hasNext) MediaControl.skipToNext,
          if (_hasMedia)
            MediaControl.custom(
              androidIcon: _liked ? 'drawable/ic_liked' : 'drawable/ic_like',
              label: _liked ? 'Unlike' : 'Like',
              name: likeAction,
            ),
        ],
        systemActions: const {MediaAction.playPause, MediaAction.seek},
        processingState: _processing,
        playing: _playing,
        updatePosition: _position.value,
        bufferedPosition: _buffered.value,
      ),
    );
  }
}
