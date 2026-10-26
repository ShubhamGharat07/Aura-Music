import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/services/playback/fake_playback_controller.dart';
import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/library/domain/usecases/record_play.dart';
import 'package:aura_music/features/library/domain/usecases/toggle_like.dart';
import 'package:aura_music/features/library/domain/usecases/watch_liked_tracks.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/domain/repositories/playback_session_repository.dart';
import 'package:aura_music/features/player/domain/usecases/restore_playback_session.dart';
import 'package:aura_music/features/player/domain/usecases/save_playback_session.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

final class _FakeStreamRepository implements StreamRepository {
  @override
  Future<Either<Failure, String>> resolve(Track track) async =>
      Right(track.streamUrl ?? 'https://stream.example/${track.id}');
}

final class _InMemoryLikedRepository implements LikedSongsRepository {
  final List<Track> _items = [];
  final StreamController<List<Track>> _changes = StreamController.broadcast();

  @override
  Future<List<Track>> all() async => List.of(_items);

  @override
  Stream<List<Track>> watchLiked() async* {
    yield List.of(_items);
    yield* _changes.stream;
  }

  @override
  Future<bool> isLiked(String trackId) async =>
      _items.any((t) => t.id == trackId);

  @override
  Future<bool> toggle(Track track) async {
    final index = _items.indexWhere((t) => t.id == track.id);
    final added = index < 0;
    if (added) {
      _items.insert(0, track);
    } else {
      _items.removeAt(index);
    }
    _changes.add(List.of(_items));
    return added;
  }

  @override
  Future<void> remove(String trackId) async {
    _items.removeWhere((t) => t.id == trackId);
    _changes.add(List.of(_items));
  }

  @override
  Future<void> clear() async {
    _items.clear();
    _changes.add(List.of(_items));
  }
}

final class _InMemoryHistoryRepository implements PlayHistoryRepository {
  final List<Track> recorded = [];

  @override
  Future<List<HistoryEntry>> recent({int limit = 200}) async => const [];

  @override
  Stream<List<HistoryEntry>> watchRecent({int limit = 200}) =>
      const Stream.empty();

  @override
  Future<void> record(Track track) async => recorded.add(track);

  @override
  Future<void> clear() async => recorded.clear();
}

final class _InMemorySessionRepository implements PlaybackSessionRepository {
  PlaybackSession? stored;
  int writes = 0;

  @override
  Future<PlaybackSession?> read() async => stored;

  @override
  Future<void> write(PlaybackSession session) async {
    stored = session;
    writes++;
  }

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late FakePlaybackController controller;

  const tracks = [
    Track(id: 'a', title: 'A', artist: 'X', duration: Duration(minutes: 3)),
    Track(id: 'b', title: 'B', artist: 'Y', duration: Duration(minutes: 3)),
    Track(id: 'c', title: 'C', artist: 'Z', duration: Duration(minutes: 3)),
  ];

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  PlayerBloc makeBloc({
    LikedSongsRepository? liked,
    PlayHistoryRepository? history,
    PlaybackSessionRepository? session,
  }) {
    final bloc = PlayerBloc(
      controller,
      ResolveStream(_FakeStreamRepository()),
      watchLiked: liked == null ? null : WatchLikedTracks(liked),
      toggleLike: liked == null ? null : ToggleLike(liked),
      recordPlay: history == null ? null : RecordPlay(history),
      restoreSession: session == null ? null : RestorePlaybackSession(session),
      saveSession: session == null ? null : SavePlaybackSession(session),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  setUp(() {
    controller = FakePlaybackController(tick: const Duration(milliseconds: 5));
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('a queue request auto-plays the first track', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    expect(bloc.state.status, PlaybackStatus.playing);
    expect(bloc.state.queue, tracks);
    expect(bloc.state.currentTrack, tracks.first);
  });

  test('a single track request replaces the queue', () async {
    final bloc = makeBloc();
    bloc.add(PlayerTrackRequested(tracks[1]));
    await settle();

    expect(bloc.state.queue, [tracks[1]]);
    expect(bloc.state.currentTrack, tracks[1]);
  });

  test('play/pause toggles transport', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerPlayPauseToggled());
    await settle();
    expect(bloc.state.status, PlaybackStatus.paused);

    bloc.add(const PlayerPlayPauseToggled());
    await settle();
    expect(bloc.state.status, PlaybackStatus.playing);
  });

  test('next advances within the queue', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerNextRequested());
    await settle();

    expect(bloc.state.currentIndex, 1);
    expect(bloc.state.currentTrack, tracks[1]);
  });

  test('next at the end leaves the current track playing', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks, startIndex: 2));
    await settle();

    bloc.add(const PlayerNextRequested());
    await settle();

    expect(bloc.state.currentIndex, 2);
    expect(bloc.state.status, PlaybackStatus.playing);
  });

  test('next wraps to the start with repeat all', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks, startIndex: 2));
    await settle();

    bloc.add(const PlayerRepeatCycled()); // off -> all
    await settle();
    bloc.add(const PlayerNextRequested());
    await settle();

    expect(bloc.state.currentIndex, 0);
  });

  test('previous wraps from the first track to the last', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerPreviousRequested());
    await settle();

    expect(bloc.state.currentIndex, 2);
  });

  test('shuffle toggles and repeat cycles through the modes', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerShuffleToggled());
    await settle();
    expect(bloc.state.shuffle, isTrue);

    bloc.add(const PlayerRepeatCycled());
    await settle();
    expect(bloc.state.repeat, RepeatMode.all);

    bloc.add(const PlayerRepeatCycled());
    await settle();
    expect(bloc.state.repeat, RepeatMode.one);

    bloc.add(const PlayerRepeatCycled());
    await settle();
    expect(bloc.state.repeat, RepeatMode.off);
  });

  test('seek clamps to the loaded duration', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerPlayPauseToggled()); // stop the ticking timer
    await settle();

    bloc.add(const PlayerSeekRequested(Duration(seconds: 30)));
    await settle();
    expect(controller.position.value, const Duration(seconds: 30));

    bloc.add(const PlayerSeekRequested(Duration(hours: 1)));
    await settle();
    expect(controller.position.value, const Duration(minutes: 3));
  });

  test('like toggles the id set and persists through the repository', () async {
    final liked = _InMemoryLikedRepository();
    final bloc = makeBloc(liked: liked);
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerLikeToggled('a'));
    await settle();
    expect(bloc.state.isLiked('a'), isTrue);
    expect(await liked.isLiked('a'), isTrue);

    bloc.add(const PlayerLikeToggled('a'));
    await settle();
    expect(bloc.state.isLiked('a'), isFalse);
    expect(await liked.isLiked('a'), isFalse);
  });

  test('records each played track in history', () async {
    final history = _InMemoryHistoryRepository();
    final bloc = makeBloc(history: history);

    bloc.add(const PlayerQueueRequested(tracks));
    await settle();
    expect(history.recorded.single.id, 'a');

    bloc.add(const PlayerNextRequested());
    await settle();
    expect(history.recorded.map((t) => t.id), ['a', 'b']);
  });

  test(
    'a paused state survives long after the toggle (no late clobber)',
    () async {
      final bloc = makeBloc();
      bloc.add(const PlayerQueueRequested(tracks));
      await settle();

      bloc.add(const PlayerPlayPauseToggled());
      await settle();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(bloc.state.status, PlaybackStatus.paused);
      expect(controller.isPlaying, isFalse);
    },
  );

  test('the controller status stream drives transport state', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();
    expect(bloc.state.status, PlaybackStatus.playing);

    await controller.pause();
    await settle();
    expect(bloc.state.status, PlaybackStatus.paused);

    await controller.play();
    await settle();
    expect(bloc.state.status, PlaybackStatus.playing);
  });

  test(
    'toggling play/pause repeatedly stays in sync with the controller',
    () async {
      final bloc = makeBloc();
      bloc.add(const PlayerQueueRequested(tracks));
      await settle();

      for (var i = 0; i < 3; i++) {
        bloc.add(const PlayerPlayPauseToggled());
        await settle();
        expect(bloc.state.status, PlaybackStatus.paused);
        expect(bloc.state.isPlaying, isFalse);

        bloc.add(const PlayerPlayPauseToggled());
        await settle();
        expect(bloc.state.status, PlaybackStatus.playing);
        expect(bloc.state.isPlaying, isTrue);
      }
    },
  );

  group('session restore (PRD S06)', () {
    test('restores the queue paused at the saved position', () async {
      final session = _InMemorySessionRepository()
        ..stored = const PlaybackSession(
          queue: tracks,
          index: 1,
          position: Duration(seconds: 30),
        );
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerSessionRestoreRequested());
      await settle();

      expect(bloc.state.queue, tracks);
      expect(bloc.state.currentTrack, tracks[1]);
      expect(bloc.state.status, PlaybackStatus.paused);
      expect(controller.position.value, const Duration(seconds: 30));
      expect(controller.isPlaying, isFalse);
    });

    test('restores shuffle and repeat', () async {
      final session = _InMemorySessionRepository()
        ..stored = const PlaybackSession(
          queue: tracks,
          index: 0,
          shuffle: true,
          repeat: RepeatMode.one,
        );
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerSessionRestoreRequested());
      await settle();

      expect(bloc.state.shuffle, isTrue);
      expect(bloc.state.repeat, RepeatMode.one);
    });

    test('playing after a restore resumes from the saved position', () async {
      final session = _InMemorySessionRepository()
        ..stored = const PlaybackSession(
          queue: tracks,
          index: 0,
          position: Duration(seconds: 45),
        );
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerSessionRestoreRequested());
      await settle();
      bloc.add(const PlayerPlayPauseToggled());
      await settle();

      expect(bloc.state.status, PlaybackStatus.playing);
      expect(
        controller.position.value,
        greaterThanOrEqualTo(const Duration(seconds: 45)),
      );
    });

    test('a restore never clobbers an active session', () async {
      final session = _InMemorySessionRepository()
        ..stored = const PlaybackSession(queue: tracks, index: 0);
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerQueueRequested(tracks, startIndex: 2));
      await settle();
      bloc.add(const PlayerSessionRestoreRequested());
      await settle();

      expect(bloc.state.currentIndex, 2);
      expect(bloc.state.status, PlaybackStatus.playing);
    });

    test('an unconfigured session store leaves the player idle', () async {
      final bloc = makeBloc();

      bloc.add(const PlayerSessionRestoreRequested());
      await settle();

      expect(bloc.state.currentTrack, isNull);
      expect(bloc.state.status, PlaybackStatus.idle);
    });

    test('autosaves the queue, index, position and transport flags', () async {
      final session = _InMemorySessionRepository();
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerQueueRequested(tracks));
      await settle();
      expect(session.stored?.queue, tracks);
      expect(session.stored?.index, 0);
      expect(session.stored?.shuffle, isFalse);

      bloc.add(const PlayerNextRequested());
      await settle();
      expect(session.stored?.index, 1);

      bloc.add(const PlayerShuffleToggled());
      await settle();
      expect(session.stored?.shuffle, isTrue);

      bloc.add(const PlayerSeekRequested(Duration(seconds: 12)));
      await settle();
      expect(session.stored?.position, const Duration(seconds: 12));
    });

    test('nothing is saved while no track is loaded', () async {
      final session = _InMemorySessionRepository();
      final bloc = makeBloc(session: session);

      bloc.add(const PlayerShuffleToggled());
      bloc.add(const PlayerRepeatCycled());
      await settle();

      expect(session.writes, 0);
    });
  });

  group('party snapshot (PRD S06 listen together)', () {
    test('adopts the shared queue, flags and position', () async {
      final history = _InMemoryHistoryRepository();
      final bloc = makeBloc(history: history);

      bloc.add(
        const PlayerSnapshotApplied(
          tracks: tracks,
          index: 2,
          position: Duration(seconds: 30),
          playing: true,
          shuffle: true,
          repeat: RepeatMode.all,
        ),
      );
      await settle();

      expect(bloc.state.queue, tracks);
      expect(bloc.state.currentTrack, tracks[2]);
      expect(bloc.state.shuffle, isTrue);
      expect(bloc.state.repeat, RepeatMode.all);
      expect(bloc.state.status, PlaybackStatus.playing);
      expect(
        controller.position.value,
        greaterThanOrEqualTo(const Duration(seconds: 30)),
      );
      // Following somebody else's queue is not the follower's history.
      expect(history.recorded, isEmpty);
    });

    test('a paused snapshot stays paused at the shared position', () async {
      final bloc = makeBloc();

      bloc.add(
        const PlayerSnapshotApplied(
          tracks: tracks,
          index: 1,
          position: Duration(seconds: 12),
        ),
      );
      await settle();

      expect(bloc.state.status, PlaybackStatus.paused);
      expect(controller.isPlaying, isFalse);
      expect(controller.position.value, const Duration(seconds: 12));
    });
  });
}
