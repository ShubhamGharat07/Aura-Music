import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/services/playback/fake_playback_controller.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

final class _FakeStreamRepository implements StreamRepository {
  @override
  Future<Either<Failure, String>> resolve(Track track) async =>
      Right(track.streamUrl ?? 'https://stream.example/${track.id}');
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

  PlayerBloc makeBloc() {
    final bloc = PlayerBloc(controller, ResolveStream(_FakeStreamRepository()));
    addTearDown(bloc.close);
    return bloc;
  }

  setUp(() {
    controller = FakePlaybackController(tick: const Duration(milliseconds: 5));
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('reorders the queue while the current track keeps playing', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerQueueReordered(2, 1));
    await settle();

    expect(bloc.state.queue.map((t) => t.id), ['a', 'c', 'b']);
    expect(bloc.state.currentTrack, tracks.first);
  });

  test('removes an up-next item', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerQueueItemRemoved(1));
    await settle();

    expect(bloc.state.queue.map((t) => t.id), ['a', 'c']);
    expect(bloc.state.currentIndex, 0);
  });

  test('removing an earlier item shifts the current index', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks, startIndex: 2));
    await settle();

    bloc.add(const PlayerQueueItemRemoved(0));
    await settle();

    expect(bloc.state.queue.map((t) => t.id), ['b', 'c']);
    expect(bloc.state.currentIndex, 1);
    expect(bloc.state.currentTrack?.id, 'c');
  });

  test('clear keeps only the current track', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerQueueCleared());
    await settle();

    expect(bloc.state.queue, [tracks.first]);
    expect(bloc.state.currentIndex, 0);
  });

  test('shuffle keeps the current track and permutes the rest', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerQueueShuffled());
    await settle();

    expect(bloc.state.queue.first, tracks.first);
    expect(bloc.state.queue.length, 3);
    expect(bloc.state.queue.map((t) => t.id).toSet(), {'a', 'b', 'c'});
  });

  test(
    'append adds to the end and play-next inserts after the current',
    () async {
      final bloc = makeBloc();
      bloc.add(const PlayerQueueRequested(tracks));
      await settle();

      bloc.add(PlayerQueueTrackPlayNext(tracks[2]));
      await settle();
      expect(bloc.state.queue.map((t) => t.id), ['a', 'c', 'b', 'c']);

      bloc.add(
        const PlayerQueueTrackAppended(Track(id: 'd', title: 'D', artist: 'W')),
      );
      await settle();
      expect(bloc.state.queue.last.id, 'd');
      expect(bloc.state.currentTrack, tracks.first);
    },
  );

  test('select jumps to a queue item and plays it', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PlayerQueueSelected(2));
    await settle();

    expect(bloc.state.currentIndex, 2);
    expect(bloc.state.currentTrack, tracks[2]);
    expect(bloc.state.status, PlaybackStatus.playing);
  });

  test('appending while idle starts playback', () async {
    final bloc = makeBloc();

    bloc.add(
      const PlayerQueueTrackAppended(Track(id: 'a', title: 'A', artist: 'X')),
    );
    await settle();

    expect(bloc.state.queue.single.id, 'a');
    expect(bloc.state.status, PlaybackStatus.playing);
  });

  test('upNext reports the tracks after the current one', () async {
    final bloc = makeBloc();
    bloc.add(const PlayerQueueRequested(tracks, startIndex: 1));
    await settle();

    expect(bloc.state.upNext.map((t) => t.id), ['c']);
    expect(bloc.state.queue.map((t) => t.id), ['a', 'b', 'c']);
  });
}
