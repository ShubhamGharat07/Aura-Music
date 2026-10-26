import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/library/domain/usecases/record_play.dart';
import 'package:aura_music/features/library/domain/usecases/toggle_like.dart';
import 'package:aura_music/features/library/domain/usecases/watch_liked_tracks.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/domain/usecases/restore_playback_session.dart';
import 'package:aura_music/features/player/domain/usecases/save_playback_session.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_session_recorder.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

// Global PlayerBloc (PRD 4.1). Depends on the PlaybackController
// abstraction, never on `just_audio` directly. Position is exposed by the
// controller as a ValueListenable, so it never enters BLoC state.

/// Drives transport, queue, shuffle/repeat and likes.
final class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  /// Creates the bloc and subscribes to track completion and likes.
  PlayerBloc(
    this._controller,
    this._resolveStream, {
    WatchLikedTracks? watchLiked,
    ToggleLike? toggleLike,
    RecordPlay? recordPlay,
    RestorePlaybackSession? restoreSession,
    SavePlaybackSession? saveSession,
    bool Function()? shouldRecordPlay,
    Future<bool> Function(String trackId)? isDownloaded,
  }) : _watchLiked = watchLiked,
       _toggleLike = toggleLike,
       _recordPlay = recordPlay,
       _restoreSession = restoreSession,
       _shouldRecordPlay = shouldRecordPlay,
       _isDownloaded = isDownloaded,
       super(const PlayerState()) {
    on<PlayerQueueRequested>(_onQueue, transformer: sequential());
    on<PlayerTrackRequested>(_onTrack);
    on<PlayerPlayPauseToggled>(_onPlayPause, transformer: droppable());
    on<PlayerNextRequested>(_onNext, transformer: droppable());
    on<PlayerPreviousRequested>(_onPrevious, transformer: droppable());
    on<PlayerSeekRequested>(_onSeek);
    on<PlayerShuffleToggled>(_onShuffle);
    on<PlayerRepeatCycled>(_onRepeat);
    on<PlayerLikeToggled>(_onLike, transformer: droppable());
    on<PlayerTrackCompleted>(_onCompleted);
    on<PlayerPlaybackStatusChanged>(_onPlaybackStatusChanged);
    on<PlayerPlaybackError>(_onPlaybackError);
    on<PlayerLikedChanged>(_onLikedChanged);
    on<PlayerQueueReordered>(_onQueueReordered, transformer: sequential());
    on<PlayerQueueItemRemoved>(_onQueueItemRemoved, transformer: sequential());
    on<PlayerQueueCleared>(_onQueueCleared, transformer: droppable());
    on<PlayerQueueShuffled>(_onQueueShuffled, transformer: sequential());
    on<PlayerQueueTrackAppended>(
      _onQueueTrackAppended,
      transformer: sequential(),
    );
    on<PlayerQueueTrackPlayNext>(
      _onQueueTrackPlayNext,
      transformer: sequential(),
    );
    on<PlayerQueueSelected>(_onQueueSelected, transformer: sequential());
    on<PlayerSessionRestoreRequested>(
      _onSessionRestore,
      transformer: droppable(),
    );
    on<PlayerSnapshotApplied>(_onSnapshotApplied, transformer: sequential());
    _completedSub = _controller.onCompleted.listen(
      (_) => add(const PlayerTrackCompleted()),
    );
    _statusSub = _controller.statusStream.listen(
      (status) => add(PlayerPlaybackStatusChanged(status)),
    );
    _errorSub = _controller.errorStream.listen(
      (message) => add(PlayerPlaybackError(message)),
    );
    _likedSub = _watchLiked?.call().listen(
      (tracks) => add(PlayerLikedChanged(tracks.map((t) => t.id).toSet())),
      onError: (Object _) {},
    );
    if (saveSession != null) {
      final recorder = PlayerSessionRecorder(
        save: saveSession,
        state: () => state,
        position: () => _controller.position.value,
      )..start();
      _recorder = recorder;
      _sessionSub = stream.listen((_) => unawaited(recorder.flush()));
    }
  }

  final PlaybackController _controller;
  final ResolveStream _resolveStream;
  final WatchLikedTracks? _watchLiked;
  final ToggleLike? _toggleLike;
  final RecordPlay? _recordPlay;
  final RestorePlaybackSession? _restoreSession;
  final bool Function()? _shouldRecordPlay;
  final Future<bool> Function(String trackId)? _isDownloaded;
  final Random _random = Random();
  late final StreamSubscription<void> _completedSub;
  late final StreamSubscription<PlaybackStatus> _statusSub;
  late final StreamSubscription<String> _errorSub;
  StreamSubscription<List<Track>>? _likedSub;
  StreamSubscription<PlayerState>? _sessionSub;
  PlayerSessionRecorder? _recorder;
  String? _loadedTrackId;
  bool _loadFailed = false;
  int _loadToken = 0;
  int? _forcedNextIndex;

  /// Exposes the controller so the UI can bind position ValueListenables.
  PlaybackController get controller => _controller;

  Future<void> _onQueue(
    PlayerQueueRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.tracks.isEmpty) return;
    _forcedNextIndex = null;
    final index = event.startIndex.clamp(0, event.tracks.length - 1);
    emit(
      state.copyWith(
        queue: event.tracks,
        currentIndex: index,
        status: PlaybackStatus.loading,
      ),
    );
    await _loadCurrent(emit);
  }

  Future<void> _onTrack(
    PlayerTrackRequested event,
    Emitter<PlayerState> emit,
  ) async {
    _forcedNextIndex = null;
    emit(
      state.copyWith(
        queue: [event.track],
        currentIndex: 0,
        status: PlaybackStatus.loading,
      ),
    );
    await _loadCurrent(emit);
  }

  Future<void> _onPlayPause(
    PlayerPlayPauseToggled event,
    Emitter<PlayerState> emit,
  ) async {
    final track = state.currentTrack;
    if (track == null) return;
    // Nothing loaded (restore failed / stream was swapped): rebuild the
    // source before toggling, otherwise play() is a silent no-op.
    if (_loadedTrackId != track.id || state.status == PlaybackStatus.error) {
      // Already resolving/loading: ignore repeat taps instead of spawning a
      // second URL resolution. A failure exits this state and can be retried.
      if (state.status == PlaybackStatus.loading) return;
      if (_controller.isPlaying) await _controller.pause();
      emit(state.copyWith(status: PlaybackStatus.loading));
      await _loadCurrent(emit);
      return;
    }
    // Pause whenever the UI shows "pause". Using the intent flag alone is not
    // enough: audio-focus loss can leave `playing` true while the OS paused
    // the stream, which used to make the first play tap do nothing.
    if (state.status == PlaybackStatus.playing) {
      await _controller.pause();
      return;
    }
    if (_controller.isPlaying) {
      await _controller.pause();
      // While buffering the intent flag is already true; tapping was a request
      // to stop, not to restart.
      if (state.status == PlaybackStatus.loading) return;
    }
    try {
      await _controller.play();
    } on Object catch (error) {
      _loadFailed = true;
      _loadedTrackId = null;
      emit(state.copyWith(status: PlaybackStatus.error, error: '$error'));
    }
  }

  Future<void> _onNext(
    PlayerNextRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final next = _resolveNext();
    // End of the queue with repeat off: keep the current track where it is
    // instead of silently pausing it (the old behaviour looked like a dead
    // Next button when the last queued song was selected).
    if (next == null) return;
    emit(state.copyWith(currentIndex: next, status: PlaybackStatus.loading));
    await _loadCurrent(emit);
  }

  Future<void> _onPrevious(
    PlayerPreviousRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.queue.isEmpty) return;
    final index = state.shuffle
        ? _random.nextInt(state.queue.length)
        : (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    emit(state.copyWith(currentIndex: index, status: PlaybackStatus.loading));
    await _loadCurrent(emit);
  }

  Future<void> _onSeek(
    PlayerSeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    await _controller.seek(event.position);
    unawaited(_recorder?.flush() ?? Future<void>.value());
  }

  void _onShuffle(PlayerShuffleToggled event, Emitter<PlayerState> emit) {
    emit(state.copyWith(shuffle: !state.shuffle));
  }

  void _onRepeat(PlayerRepeatCycled event, Emitter<PlayerState> emit) {
    emit(state.copyWith(repeat: state.repeat.next));
  }

  Future<void> _onLike(
    PlayerLikeToggled event,
    Emitter<PlayerState> emit,
  ) async {
    final next = {...state.likedIds};
    if (!next.add(event.trackId)) next.remove(event.trackId);
    emit(state.copyWith(likedIds: next));
    final toggle = _toggleLike;
    if (toggle == null) return;
    for (final track in state.queue) {
      if (track.id == event.trackId) {
        try {
          await toggle(track);
        } on Object {
          // A persistence failure must not break playback.
        }
        return;
      }
    }
  }

  /// Keeps [PlayerState.likedIds] in sync with the persisted liked songs.
  void _onLikedChanged(PlayerLikedChanged event, Emitter<PlayerState> emit) =>
      emit(state.copyWith(likedIds: event.likedIds));

  Future<void> _onQueueReordered(
    PlayerQueueReordered event,
    Emitter<PlayerState> emit,
  ) async {
    final queue = [...state.queue];
    if (event.oldIndex < 0 || event.oldIndex >= queue.length) return;
    _forcedNextIndex = null;
    final newIndex = event.newIndex.clamp(0, queue.length - 1);
    if (newIndex == event.oldIndex) return;
    final currentIndex = state.currentIndex;
    final moved = queue.removeAt(event.oldIndex);
    queue.insert(newIndex, moved);
    // Track the current row by index movement, not by track id: the queue can
    // legitimately contain the same song twice (Play next / Add to queue), and
    // an id lookup would jump to the wrong duplicate.
    final int nextCurrent;
    if (event.oldIndex == currentIndex) {
      nextCurrent = newIndex;
    } else if (event.oldIndex < currentIndex && newIndex >= currentIndex) {
      nextCurrent = currentIndex - 1;
    } else if (event.oldIndex > currentIndex && newIndex <= currentIndex) {
      nextCurrent = currentIndex + 1;
    } else {
      nextCurrent = currentIndex;
    }
    emit(state.copyWith(queue: queue, currentIndex: nextCurrent));
  }

  Future<void> _onQueueItemRemoved(
    PlayerQueueItemRemoved event,
    Emitter<PlayerState> emit,
  ) async {
    final index = event.index;
    if (index < 0 ||
        index >= state.queue.length ||
        index == state.currentIndex) {
      return;
    }
    final queue = [...state.queue]..removeAt(index);
    final currentIndex = index < state.currentIndex
        ? state.currentIndex - 1
        : state.currentIndex;
    final forced = _forcedNextIndex;
    if (forced != null) {
      if (forced == index) {
        _forcedNextIndex = null;
      } else if (forced > index) {
        _forcedNextIndex = forced - 1;
      }
    }
    emit(state.copyWith(queue: queue, currentIndex: currentIndex));
  }

  Future<void> _onQueueCleared(
    PlayerQueueCleared event,
    Emitter<PlayerState> emit,
  ) async {
    final track = state.currentTrack;
    if (track == null) return;
    _forcedNextIndex = null;
    emit(state.copyWith(queue: [track], currentIndex: 0));
  }

  Future<void> _onQueueShuffled(
    PlayerQueueShuffled event,
    Emitter<PlayerState> emit,
  ) async {
    final offset = state.currentIndex + 1;
    if (offset >= state.queue.length) return;
    _forcedNextIndex = null;
    final head = state.queue.sublist(0, offset);
    final tail = [...state.queue.sublist(offset)]..shuffle(_random);
    emit(state.copyWith(queue: [...head, ...tail]));
  }

  Future<void> _onQueueTrackAppended(
    PlayerQueueTrackAppended event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.currentTrack == null) {
      emit(
        state.copyWith(
          queue: [event.track],
          currentIndex: 0,
          status: PlaybackStatus.loading,
        ),
      );
      await _loadCurrent(emit);
      return;
    }
    emit(state.copyWith(queue: [...state.queue, event.track]));
  }

  Future<void> _onQueueTrackPlayNext(
    PlayerQueueTrackPlayNext event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.currentTrack == null) {
      emit(
        state.copyWith(
          queue: [event.track],
          currentIndex: 0,
          status: PlaybackStatus.loading,
        ),
      );
      await _loadCurrent(emit);
      return;
    }
    final insertAt = state.currentIndex + 1;
    final queue = [...state.queue]..insert(insertAt, event.track);
    // "Play next" must win even with shuffle enabled; consumed by _resolveNext.
    _forcedNextIndex = insertAt;
    emit(state.copyWith(queue: queue));
  }

  Future<void> _onQueueSelected(
    PlayerQueueSelected event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.queue.length) return;
    if (event.index == state.currentIndex) return;
    _forcedNextIndex = null;
    emit(
      state.copyWith(currentIndex: event.index, status: PlaybackStatus.loading),
    );
    await _loadCurrent(emit);
  }

  /// Restores the last queue + position, paused (PRD S06). Never clobbers an
  /// active session, never auto-plays and never records a history entry.
  Future<void> _onSessionRestore(
    PlayerSessionRestoreRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final restore = _restoreSession;
    if (restore == null || state.currentTrack != null) return;
    final session = (await restore(const NoParams())).getOrElse((_) => null);
    final track = session?.current;
    if (session == null || track == null) return;
    _forcedNextIndex = null;
    emit(
      state.copyWith(
        queue: session.queue,
        currentIndex: session.index.clamp(0, session.queue.length - 1),
        shuffle: session.shuffle,
        repeat: session.repeat,
        status: PlaybackStatus.paused,
      ),
    );
    await _loadSnapshot(emit, startAt: session.position, autoPlay: false);
  }

  /// Adopts state shared by a party session (PRD S06 "listen together"): the
  /// host owns the queue and the transport flag, so both are followed.
  Future<void> _onSnapshotApplied(
    PlayerSnapshotApplied event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.tracks.isEmpty) return;
    _forcedNextIndex = null;
    emit(
      state.copyWith(
        queue: event.tracks,
        currentIndex: event.index.clamp(0, event.tracks.length - 1),
        shuffle: event.shuffle,
        repeat: event.repeat,
        status: event.playing ? PlaybackStatus.loading : PlaybackStatus.paused,
      ),
    );
    await _loadSnapshot(emit, startAt: event.position, autoPlay: event.playing);
  }

  /// Loads the current track at [startAt], starting playback when [autoPlay].
  /// Shared by the startup restore and a party snapshot: neither records a
  /// history entry, and a failed load (a stale stream) only leaves the track
  /// paused, so the next play tap can refresh the url.
  Future<void> _loadSnapshot(
    Emitter<PlayerState> emit, {
    required Duration startAt,
    required bool autoPlay,
  }) async {
    final track = state.currentTrack;
    if (track == null) return;
    final token = ++_loadToken;
    _loadFailed = false;
    final resolved = await _withStreamUrl(track);
    if (token != _loadToken) return;
    if (resolved == null) {
      _loadedTrackId = null;
      if (autoPlay) _emitFailure(emit, 'Stream unavailable');
      return;
    }
    try {
      await _controller.load(resolved, startAt: startAt, autoPlay: autoPlay);
      if (token != _loadToken) return;
      _loadedTrackId = track.id;
      _loadFailed = false;
    } on Object {
      if (token != _loadToken) return;
      _loadedTrackId = null;
    }
  }

  /// Mirrors the controller's transport status into [PlayerState]. Idle is a
  /// transient engine state during a source swap, so it never reaches the UI.
  /// A load failure is latched until the next load attempt, so a stale source
  /// cannot overwrite the error with a spurious `paused`.
  void _onPlaybackStatusChanged(
    PlayerPlaybackStatusChanged event,
    Emitter<PlayerState> emit,
  ) {
    if (_loadFailed || event.status == PlaybackStatus.idle) return;
    if (state.status == event.status) return;
    emit(state.copyWith(status: event.status));
  }

  /// Surfaces an engine-level failure (decoder, source, audio session). The
  /// play button stays live: tapping it rebuilds the source.
  void _onPlaybackError(PlayerPlaybackError event, Emitter<PlayerState> emit) {
    if (state.currentTrack == null) return;
    _loadedTrackId = null;
    _loadFailed = true;
    emit(state.copyWith(status: PlaybackStatus.error, error: event.message));
  }

  Future<void> _onCompleted(
    PlayerTrackCompleted event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.repeat == RepeatMode.one) {
      await _loadCurrent(emit);
      return;
    }
    add(const PlayerNextRequested());
  }

  Future<void> _loadCurrent(Emitter<PlayerState> emit) async {
    final track = state.currentTrack;
    if (track == null) return;
    final token = ++_loadToken;
    _loadFailed = false;
    final resolved = await _withStreamUrl(track);
    if (token != _loadToken) return;
    if (resolved == null) {
      _emitFailure(emit, 'Stream unavailable');
      return;
    }
    if (await _tryLoad(resolved, token)) {
      await _recordSuccessfulLoad(resolved);
      return;
    }
    if (token != _loadToken) return;
    // One automatic retry with a freshly resolved URL: CDN URLs can expire
    // between the catalog response and the tap, which used to leave play/pause
    // inert. Keep the UI in loading while the retry runs.
    _loadFailed = false;
    emit(state.copyWith(status: PlaybackStatus.loading, error: null));
    final retried = await _withStreamUrl(track);
    if (token != _loadToken) return;
    if (retried == null || !await _tryLoad(retried, token)) {
      _emitFailure(emit, 'Could not play this track');
      return;
    }
    await _recordSuccessfulLoad(retried);
  }

  Future<bool> _tryLoad(Track track, int token) async {
    try {
      await _controller.load(track);
    } on Object {
      return false;
    }
    if (token != _loadToken) return false;
    _loadedTrackId = track.id;
    _loadFailed = false;
    return true;
  }

  Future<void> _recordSuccessfulLoad(Track track) async {
    if (!(_shouldRecordPlay?.call() ?? true)) return;
    final record = _recordPlay;
    if (record == null) return;
    try {
      await record(track);
    } on Object {
      // History persistence must not break playback.
    }
  }

  void _emitFailure(Emitter<PlayerState> emit, String message) {
    _loadedTrackId = null;
    _loadFailed = true;
    emit(state.copyWith(status: PlaybackStatus.error, error: message));
  }

  /// Resolves a fresh playback URL. Downloaded tracks still get one as a
  /// fallback (the controller prefers the local file and only falls back to
  /// the URL when the file is unreadable); when the network is down the track
  /// is returned as-is so offline playback keeps working.
  Future<Track?> _withStreamUrl(Track track) async {
    final local = await _isLocal(track.id);
    try {
      final result = await _resolveStream(track);
      final resolved = result.fold<String?>((_) => null, (url) => url);
      if (resolved != null && resolved.isNotEmpty) {
        return track.copyWith(streamUrl: resolved);
      }
    } on Object {
      // A resolver crash is treated like a failed resolution.
    }
    return local ? track : null;
  }

  Future<bool> _isLocal(String trackId) async {
    final check = _isDownloaded;
    if (check == null) return false;
    try {
      return await check(trackId);
    } on Object {
      return false;
    }
  }

  /// Next index honouring shuffle and repeat; null when the queue may stop.
  int? _resolveNext() {
    if (state.queue.isEmpty) return null;
    final forced = _forcedNextIndex;
    if (forced != null) {
      _forcedNextIndex = null;
      if (forced >= 0 && forced < state.queue.length) return forced;
    }
    if (state.queue.length == 1) {
      return state.repeat == RepeatMode.all ? 0 : null;
    }
    if (state.shuffle) {
      var index = _random.nextInt(state.queue.length);
      if (index == state.currentIndex) index = (index + 1) % state.queue.length;
      return index;
    }
    final next = state.currentIndex + 1;
    if (next >= state.queue.length) {
      return state.repeat == RepeatMode.all ? 0 : null;
    }
    return next;
  }

  @override
  Future<void> close() async {
    await _completedSub.cancel();
    await _statusSub.cancel();
    await _errorSub.cancel();
    await _likedSub?.cancel();
    await _sessionSub?.cancel();
    _recorder?.dispose();
    return super.close();
  }
}
