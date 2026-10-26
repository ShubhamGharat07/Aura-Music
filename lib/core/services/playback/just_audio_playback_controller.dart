import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Real [PlaybackController] backed by `just_audio`. Streams the resolved
/// [Track.streamUrl] (JioSaavn CDN) and mirrors the player's high-frequency
/// position / buffered position onto [ValueListenable]s.
///
/// Registered in DI; the fake controller is only used by tests.

/// just_audio-backed transport.
final class JustAudioPlaybackController implements PlaybackController {
  /// Creates the controller and wires the player streams.
  JustAudioPlaybackController({
    AudioPlayer? player,
    LocalFileResolver? localFileResolver,
  }) : _player = player ?? AudioPlayer(),
       _localFileResolver = localFileResolver {
    _positionSub = _player.positionStream.listen(_onPosition);
    _bufferedSub = _player.bufferedPositionStream.listen(
      (p) => _buffered.value = p,
    );
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
    _errorSub = _player.errorStream.listen(_reportError);
  }

  static const Duration _loadTimeout = Duration(seconds: 30);

  final AudioPlayer _player;
  final LocalFileResolver? _localFileResolver;
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _buffered = ValueNotifier(Duration.zero);
  final StreamController<void> _completed = StreamController<void>.broadcast();
  final StreamController<PlaybackStatus> _status =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<String> _errors = StreamController<String>.broadcast();
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration> _bufferedSub;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<PlayerException> _errorSub;
  PlaybackStatus? _lastStatus;
  ProcessingState? _lastProcessing;
  bool _hasSource = false;
  bool _sourceReady = false;
  String? _currentTrackId;
  int _loadGeneration = 0;

  @override
  ValueListenable<Duration> get position => _position;

  @override
  ValueListenable<Duration> get buffered => _buffered;

  @override
  Duration get duration => _player.duration ?? Duration.zero;

  @override
  bool get isPlaying => _player.playing;

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
    final generation = ++_loadGeneration;
    _hasSource = false;
    _sourceReady = false;
    _currentTrackId = track.id;
    _position.value = Duration.zero;
    _buffered.value = Duration.zero;

    String? localFile;
    try {
      localFile = await _localFileResolver?.call(track.id);
    } on Object {
      localFile = null;
    }
    if (generation != _loadGeneration) return;

    if (!autoPlay && _player.playing) {
      try {
        await _player.pause();
      } on Object {
        // A failed pause must not prevent the new source from loading.
      }
      if (generation != _loadGeneration) return;
    }

    try {
      if (localFile != null) {
        try {
          await _player
              .setFilePath(localFile, initialPosition: startAt, tag: track.id)
              .timeout(_loadTimeout);
          if (generation != _loadGeneration) return;
          _hasSource = true;
        } on Object {
          if (generation != _loadGeneration) return;
          // The downloaded file is missing/corrupt: fall through to streaming.
          _hasSource = false;
        }
      }
      if (!_hasSource) {
        final url = track.streamUrl;
        if (url == null || url.isEmpty) {
          throw StateError('Track ${track.id} has no stream URL');
        }
        await _player
            .setUrl(url, initialPosition: startAt, tag: track.id)
            .timeout(_loadTimeout);
        if (generation != _loadGeneration) return;
        _hasSource = true;
      }
      if (!autoPlay) {
        await _player.pause();
        return;
      }
      // just_audio's play() completes only when playback *finishes*, so it must
      // never be awaited: awaiting it stalls the load and desyncs play/pause.
      unawaited(_playSafely());
    } on Object {
      if (generation != _loadGeneration) return;
      // Never leave a half-loaded source behind: the BLoC retries with a fresh
      // URL and the previous source must not start playing instead.
      _hasSource = false;
      _sourceReady = false;
      _currentTrackId = null;
      try {
        await _player.stop();
      } on Object {
        // The retry still gets a fresh source load.
      }
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    if (!_hasSource) {
      throw StateError('No audio source is loaded');
    }
    if (_player.playing) {
      // Intent is already true but the transport is paused/stalled (audio
      // focus loss, stalled network): reset it so play() actually runs.
      await _player.pause();
    }
    // just_audio ignores play() while the source is completed; rewind first so
    // the play button can replay the track (Spotify-style restart).
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_playSafely());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setSkipSilence(bool enabled) =>
      _player.setSkipSilenceEnabled(enabled);

  @override
  Future<void> dispose() async {
    _loadGeneration++;
    _currentTrackId = null;
    await _positionSub.cancel();
    await _bufferedSub.cancel();
    await _stateSub.cancel();
    await _errorSub.cancel();
    await _completed.close();
    await _status.close();
    await _errors.close();
    await _player.dispose();
    _position.dispose();
    _buffered.dispose();
  }

  /// Starts playback without blocking the event loop, surfacing engine errors
  /// (audio focus denied, decoder failure) to the BLoC.
  Future<void> _playSafely() async {
    try {
      await _player.play();
    } on PlayerInterruptedException {
      // A newer load/pause superseded this request; not an error.
    } on Object catch (error) {
      _reportError(error);
    }
  }

  void _reportError(Object error) {
    if (_errors.isClosed) return;
    final message = error is PlayerException
        ? (error.message ?? 'Audio playback failed')
        : error.toString();
    _errors.add(message);
  }

  void _onPosition(Duration value) {
    if (value != _position.value) _position.value = value;
  }

  void _onPlayerState(PlayerState state) {
    final processing = state.processingState;
    final sourceTag = _player.sequenceState.currentSource?.tag;
    final isCurrentSource =
        _currentTrackId != null && sourceTag == _currentTrackId;
    final status = switch (processing) {
      ProcessingState.idle => PlaybackStatus.idle,
      ProcessingState.loading ||
      ProcessingState.buffering => PlaybackStatus.loading,
      ProcessingState.completed => PlaybackStatus.paused,
      ProcessingState.ready =>
        state.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
    };
    if (status != _lastStatus && !_status.isClosed) {
      _lastStatus = status;
      _status.add(status);
    }
    if (processing == ProcessingState.ready && isCurrentSource) {
      _sourceReady = true;
    }
    // `completed` can be re-broadcast (playing false arrives after playing
    // true), so advance exactly once per track end. Ignore a late completion
    // from the source that was just replaced.
    final justCompleted =
        processing == ProcessingState.completed &&
        isCurrentSource &&
        _sourceReady &&
        _lastProcessing != ProcessingState.completed;
    _lastProcessing = processing;
    if (justCompleted && !_completed.isClosed) _completed.add(null);
  }
}
