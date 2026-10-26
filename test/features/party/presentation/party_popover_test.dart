import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/services/playback/fake_playback_controller.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
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
import 'package:aura_music/features/party/presentation/widgets/party_popover.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

// Listen together popover: anchored under the Bluetooth button, not a sheet
// rising from the (navigation-bar covered) bottom edge.

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

  PartySession _session = const PartySession();

  void emitSession(PartySession session) {
    _session = session;
    _sessions.add(session);
  }

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
  Future<Either<Failure, Unit>> discover({required bool active}) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> join(String peerId) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> publish(
    PartySnapshot snapshot, {
    required bool full,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> leave() async {
    emitSession(const PartySession());
    return const Right(unit);
  }
}

void main() {
  late _FakePartyRepository repository;
  late FakePlaybackController controller;
  late PlayerBloc player;
  late PartyBloc party;

  setUp(() async {
    await getIt.reset();
  });

  // Built from inside the test body on purpose: the party bloc subscribes to
  // the repository streams, and a subscription created outside the widget
  // test's zone never has its microtasks flushed by `pump`, so the session
  // events would sit unread.
  void boot() {
    repository = _FakePartyRepository();
    controller = FakePlaybackController();
    player = PlayerBloc(controller, ResolveStream(_FakeStreamRepository()));
    party = PartyBloc(
      WatchPartySession(repository),
      WatchPartyMessages(repository),
      HostParty(repository),
      DiscoverParty(repository),
      JoinParty(repository),
      PublishPartyState(repository),
      LeaveParty(repository),
      player: player,
    );
    getIt.registerSingleton<PartyBloc>(party);
    addTearDown(() async {
      await party.close();
      await player.close();
      await controller.dispose();
      await repository.close();
      await getIt.reset();
    });
  }

  Widget host() => ScreenUtilInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => showPartyPopover(context),
                icon: const Icon(Icons.bluetooth_rounded),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Phone-shaped surface that matches the design size, so screen-util scaling
  // stays 1:1 with the logical pixels the popover positions itself with.
  Future<void> pumpHost(WidgetTester tester) async {
    boot();
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(host());
  }

  testWidgets('opens under its button with the idle choices', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byIcon(Icons.bluetooth_rounded));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.text('Listen together'));
    expect(card.left, greaterThan(0));
    expect(find.text('Start a session'), findsOneWidget);
    expect(find.text('Join nearby'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hosting switches the popover to the session controls', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.byIcon(Icons.bluetooth_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start a session'));
    await tester.pumpAndSettle();

    expect(find.text('Stop session'), findsOneWidget);
    expect(find.text('Waiting for someone to join…'), findsOneWidget);
  });

  testWidgets('a tap outside closes the popover', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.byIcon(Icons.bluetooth_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Listen together'), findsOneWidget);

    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();

    expect(find.text('Listen together'), findsNothing);
  });
}
