import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/services/playback/fake_playback_controller.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_role.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/entities/party_status.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';
import 'package:aura_music/features/party/domain/usecases/discover_party.dart';
import 'package:aura_music/features/party/domain/usecases/host_party.dart';
import 'package:aura_music/features/party/domain/usecases/join_party.dart';
import 'package:aura_music/features/party/domain/usecases/leave_party.dart';
import 'package:aura_music/features/party/domain/usecases/publish_party_state.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_messages.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_session.dart';
import 'package:aura_music/features/party/presentation/bloc/party_bloc.dart';
import 'package:aura_music/features/party/presentation/bloc/party_event.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

// Listen together (PRD S06): the bloc orchestration on both sides of the link.

final class _FakeStreamRepository implements StreamRepository {
  @override
  Future<Either<Failure, String>> resolve(Track track) async =>
      Right(track.streamUrl ?? 'https://stream.example/${track.id}');
}

final class _FakePartyRepository implements PartyRepository {
  final StreamController<PartySession> _sessions =
      StreamController<PartySession>.broadcast();
  final StreamController<PartyMessage> _messages =
      StreamController<PartyMessage>.broadcast();
  final List<PartySnapshot> published = [];
  final List<bool> publishedFull = [];

  PartySession _session = const PartySession();

  void emitSession(PartySession session) {
    _session = session;
    _sessions.add(session);
  }

  void emitMessage(PartyMessage message) => _messages.add(message);

  Future<void> close() async {
    await _sessions.close();
    await _messages.close();
  }

  @override
  Stream<PartySession> watch() {
    final controller = StreamController<PartySession>();
    controller.add(_session);
    final sub = _sessions.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  @override
  Stream<PartyMessage> watchMessages() => _messages.stream;

  @override
  Future<Either<Failure, Unit>> host() async {
    emitSession(
      const PartySession(role: PartyRole.host, status: PartyStatus.hosting),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> discover({required bool active}) async {
    emitSession(
      active
          ? const PartySession(
              role: PartyRole.guest,
              status: PartyStatus.scanning,
            )
          : const PartySession(),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> join(String peerId) async {
    emitSession(
      const PartySession(role: PartyRole.guest, status: PartyStatus.connecting),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> publish(
    PartySnapshot snapshot, {
    required bool full,
  }) async {
    published.add(snapshot);
    publishedFull.add(full);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> leave() async {
    emitSession(const PartySession());
    return const Right(unit);
  }
}

void main() {
  late FakePlaybackController controller;
  late PlayerBloc player;
  late _FakePartyRepository repository;
  late PartyBloc bloc;

  const tracks = [
    Track(id: 'a', title: 'A', artist: 'X', duration: Duration(minutes: 3)),
    Track(id: 'b', title: 'B', artist: 'Y', duration: Duration(minutes: 3)),
    Track(id: 'c', title: 'C', artist: 'Z', duration: Duration(minutes: 3)),
  ];

  const following = PartySession(
    role: PartyRole.guest,
    status: PartyStatus.connected,
    hostName: 'Pixel 7',
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 25));

  setUp(() {
    controller = FakePlaybackController(tick: const Duration(milliseconds: 5));
    player = PlayerBloc(controller, ResolveStream(_FakeStreamRepository()));
    repository = _FakePartyRepository();
    bloc = PartyBloc(
      WatchPartySession(repository),
      WatchPartyMessages(repository),
      HostParty(repository),
      DiscoverParty(repository),
      JoinParty(repository),
      PublishPartyState(repository),
      LeaveParty(repository),
      player: player,
      publishInterval: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    await bloc.close();
    await player.close();
    await repository.close();
    await controller.dispose();
  });

  test('the host shares its queue once a session starts', () async {
    player.add(const PlayerQueueRequested(tracks));
    await settle();

    bloc.add(const PartyHostRequested());
    await settle();

    expect(bloc.state.session.isHosting, isTrue);
    expect(repository.published, isNotEmpty);
    expect(repository.publishedFull.last, isTrue);
    final snapshot = repository.published.last;
    expect(snapshot.queue.map((t) => t.id), ['a', 'b', 'c']);
    expect(snapshot.index, 0);
    expect(snapshot.playing, isTrue);
  });

  test('the host re-shares the full state when a guest attaches', () async {
    player.add(const PlayerQueueRequested(tracks));
    await settle();
    bloc.add(const PartyHostRequested());
    await settle();
    final before = repository.published.length;

    repository.emitSession(
      const PartySession(
        role: PartyRole.host,
        status: PartyStatus.hosting,
        peers: [PartyPeer(id: 'Pixel 7', name: 'Pixel 7')],
      ),
    );
    await settle();

    expect(repository.published.length, greaterThan(before));
    expect(repository.publishedFull.last, isTrue);
  });

  test('the host sends a position tick while the queue is unchanged', () async {
    player.add(const PlayerQueueRequested(tracks));
    await settle();
    bloc.add(const PartyHostRequested());
    await settle();
    repository.published.clear();
    repository.publishedFull.clear();

    // Let the position move past the resync tolerance, the way it does
    // between two real ticks.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    bloc.add(const PartyTickElapsed());
    await settle();

    expect(repository.publishedFull, [false]);
    expect(repository.published.single.queue.map((t) => t.id), ['a', 'b', 'c']);
    expect(repository.published.single.position, greaterThan(Duration.zero));
  });

  test('a queue change is shared in full, a pause only as a tick', () async {
    player.add(const PlayerQueueRequested(tracks));
    await settle();
    bloc.add(const PartyHostRequested());
    await settle();
    repository.publishedFull.clear();

    player.add(const PlayerPlayPauseToggled());
    await settle();
    expect(repository.publishedFull, everyElement(isFalse));

    player.add(const PlayerNextRequested());
    await settle();
    expect(repository.publishedFull, contains(true));
    expect(repository.published.last.index, 1);
  });

  test('a guest adopts the host queue and position', () async {
    bloc.add(const PartyJoinRequested(PartyPeer(id: 'p1', name: 'Pixel 7')));
    await settle();
    repository.emitSession(following);
    await settle();
    expect(bloc.state.session.isFollowing, isTrue);

    repository.emitMessage(
      PartyStateMessage(
        PartySnapshot(
          queue: tracks,
          index: 2,
          position: const Duration(seconds: 30),
          playing: true,
        ),
      ),
    );
    await settle();

    expect(player.state.queue.map((t) => t.id), ['a', 'b', 'c']);
    expect(player.state.currentIndex, 2);
    expect(player.state.status, PlaybackStatus.playing);
    expect(controller.position.value.inSeconds, 30);
  });

  test('a guest is nudged back onto the host position', () async {
    repository.emitSession(following);
    await settle();
    repository.emitMessage(
      PartyStateMessage(PartySnapshot(queue: tracks, index: 0, playing: true)),
    );
    await settle();

    repository.emitMessage(
      const PartyTickMessage(
        index: 0,
        position: Duration(seconds: 10),
        playing: true,
      ),
    );
    await settle();

    expect(controller.position.value.inSeconds, greaterThanOrEqualTo(10));
  });

  test('a paused host pauses the guest', () async {
    repository.emitSession(following);
    await settle();
    repository.emitMessage(
      PartyStateMessage(PartySnapshot(queue: tracks, index: 0, playing: true)),
    );
    await settle();
    expect(player.state.status, PlaybackStatus.playing);

    repository.emitMessage(
      PartyTickMessage(
        index: 0,
        position: controller.position.value,
        playing: false,
      ),
    );
    await settle();

    expect(player.state.status, PlaybackStatus.paused);
  });

  test('a guest ignores what the host sends once it left', () async {
    repository.emitMessage(
      PartyStateMessage(PartySnapshot(queue: tracks, index: 1, playing: true)),
    );
    await settle();

    expect(player.state.queue, isEmpty);
  });

  test('leaving clears the notice about the ended session', () async {
    repository.emitSession(following);
    await settle();

    bloc.add(const PartyLeaveRequested());
    await settle();

    expect(bloc.state.session.status, PartyStatus.idle);
    expect(bloc.state.session.isActive, isFalse);
  });
}
