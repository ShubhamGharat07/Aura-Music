import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Temporary timer-driven controller: makes the Now Playing screen feel
// alive (position ticks) without native audio. Swapped for the
// just_audio-backed implementation in Phase 1 (DI-only change).

/// Fake [PlaybackController] that ticks position with a periodic timer.
final class FakePlaybackController implements PlaybackController {
  /// Creates the fake controller.
  FakePlaybackController({this.tick = const Duration(milliseconds: 250)});

  /// Timer tick.
  final Duration tick;

  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _buffered = ValueNotifier(Duration.zero);
  final StreamController<void> _completed = StreamController<void>.broadcast();
  final StreamController<PlaybackStatus> _status =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();

  Timer? _timer;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _skipSilence = false;
  bool _playing = false;
  PlaybackStatus _lastStatus = PlaybackStatus.idle;

  @override
  ValueListenable<Duration> get position => _position;

  @override
  ValueListenable<Duration> get buffered => _buffered;

  @override
  Duration get duration => _duration;

  @override
  bool get isPlaying => _playing;

  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;

  @override
  Stream<String> get errorStream => _errors.stream;

  @override
  Stream<void> get onCompleted => _completed.stream;

  @override
  Future<void> load(
    Track track, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  }) async {
    _duration = track.duration == Duration.zero
        ? const Duration(minutes: 3, seconds: 30)
        : track.duration;
    _position.value = startAt;
    _buffered.value = Duration.zero;
    _startBuffering();
    _emitStatus(PlaybackStatus.loading);
    if (!autoPlay) {
      _playing = false;
      _emitStatus(PlaybackStatus.paused);
      return;
    }
    await play();
  }

  @override
  Future<void> play() async {
    _playing = true;
    _emitStatus(PlaybackStatus.playing);
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => _advance());
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _emitStatus(PlaybackStatus.paused);
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> seek(Duration position) async {
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > _duration ? _duration : position);
    _position.value = clamped;
  }

  @override
  Future<void> setSpeed(double speed) async => _speed = speed;

  @override
  Future<void> setSkipSilence(bool enabled) async => _skipSilence = enabled;

  /// Current fake rate; exposed for tests.
  double get speed => _speed;

  /// Current fake skip-silence flag; exposed for tests.
  bool get skipSilence => _skipSilence;

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _completed.close();
    await _status.close();
    await _errors.close();
    _position.dispose();
    _buffered.dispose();
  }

  void _emitStatus(PlaybackStatus status) {
    if (status != _lastStatus && !_status.isClosed) {
      _lastStatus = status;
      _status.add(status);
    }
  }

  void _advance() {
    final next = _position.value + tick;
    if (next >= _duration) {
      _position.value = _duration;
      _playing = false;
      _timer?.cancel();
      _emitStatus(PlaybackStatus.paused);
      _completed.add(null);
      return;
    }
    _position.value = next;
    final buffer = next + const Duration(seconds: 10);
    _buffered.value = buffer > _duration ? _duration : buffer;
  }

  void _startBuffering() {
    _buffered.value = _duration < const Duration(seconds: 12)
        ? _duration
        : const Duration(seconds: 12);
  }
}
