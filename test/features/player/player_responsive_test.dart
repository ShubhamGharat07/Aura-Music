import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:aura_music/features/lyrics/domain/usecases/get_lyrics.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';
import 'package:aura_music/features/party/domain/usecases/discover_party.dart';
import 'package:aura_music/features/party/domain/usecases/host_party.dart';
import 'package:aura_music/features/party/domain/usecases/join_party.dart';
import 'package:aura_music/features/party/domain/usecases/leave_party.dart';
import 'package:aura_music/features/party/domain/usecases/publish_party_state.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_messages.dart';
import 'package:aura_music/features/party/domain/usecases/watch_party_session.dart';
import 'package:aura_music/features/party/presentation/bloc/party_bloc.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/pages/player_page.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

import '../../helpers/window_sizes.dart';

// Responsive gate (PRD 12.1): Now Playing must render without overflow at
// all 8 window sizes. Uses a silent (no-timer) controller so no pending
// timers leak into the test.

final class _NoLyricsRepository implements LyricsRepository {
  @override
  Future<Either<Failure, Lyrics?>> forTrack(Track track) async =>
      const Right(null);
}

final class _PassThroughStreamRepository implements StreamRepository {
  @override
  Future<Either<Failure, String>> resolve(Track track) async =>
      Right(track.streamUrl ?? 'https://stream.example/${track.id}');
}

final class _SilentController implements PlaybackController {
  final ValueNotifier<Duration> _pos = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _buf = ValueNotifier(Duration.zero);
  final StreamController<void> _done = StreamController<void>.broadcast();
  final StreamController<PlaybackStatus> _status =
      StreamController<PlaybackStatus>.broadcast();
  Duration _duration = Duration.zero;

  @override
  ValueListenable<Duration> get position => _pos;
  @override
  ValueListenable<Duration> get buffered => _buf;
  @override
  Duration get duration => _duration;
  @override
  bool get isPlaying => false;
  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;
  @override
  Stream<String> get errorStream => const Stream.empty();
  @override
  Stream<void> get onCompleted => _done.stream;

  @override
  Future<void> load(
    Track track, {
    Duration startAt = Duration.zero,
    bool autoPlay = true,
  }) async {
    _duration = track.duration;
    _pos.value = startAt;
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async => _pos.value = position;
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setSkipSilence(bool enabled) async {}

  @override
  Future<void> dispose() async {
    await _done.close();
    await _status.close();
    _pos.dispose();
    _buf.dispose();
  }
}

final class _IdlePartyRepository implements PartyRepository {
  final StreamController<PartySession> _sessions =
      StreamController<PartySession>.broadcast();
  final StreamController<PartyMessage> _messages =
      StreamController<PartyMessage>.broadcast();

  @override
  Stream<PartySession> watch() => _sessions.stream;

  @override
  Stream<PartyMessage> watchMessages() => _messages.stream;

  @override
  Future<Either<Failure, Unit>> host() async => const Right(unit);

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
  Future<Either<Failure, Unit>> leave() async => const Right(unit);
}

void main() {
  late _SilentController controller;

  setUp(() async {
    await getIt.reset();
    controller = _SilentController();
    getIt.registerLazySingleton<PlayerBloc>(
      () =>
          PlayerBloc(controller, ResolveStream(_PassThroughStreamRepository())),
      dispose: (bloc) => bloc.close(),
    );
    getIt.registerFactory<LyricsCubit>(
      () => LyricsCubit(GetLyrics(_NoLyricsRepository())),
    );
    final party = _IdlePartyRepository();
    getIt.registerLazySingleton<PartyBloc>(
      () => PartyBloc(
        WatchPartySession(party),
        WatchPartyMessages(party),
        HostParty(party),
        DiscoverParty(party),
        JoinParty(party),
        PublishPartyState(party),
        LeaveParty(party),
        player: getIt<PlayerBloc>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
    getIt<PlayerBloc>().add(
      const PlayerQueueRequested([
        Track(
          id: 'local-1',
          title: 'Responsive Track',
          artist: 'Layout Lab',
          album: 'Sizes',
          duration: Duration(minutes: 3, seconds: 30),
        ),
      ]),
    );
  });

  tearDown(() async {
    await controller.dispose();
    await getIt.reset();
  });

  for (final size in kWindowSizes) {
    final design = switch (WindowSizeClass.ofWidth(size.width)) {
      WindowSizeClass.compact => const Size(393, 852),
      WindowSizeClass.medium => const Size(744, 1133),
      WindowSizeClass.expanded ||
      WindowSizeClass.large => const Size(1194, 834),
    };
    testWidgets('Now Playing has no overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = Size(size.width * 3, size.height * 3);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: design,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            home: BlocProvider<PlayerBloc>.value(
              value: getIt<PlayerBloc>(),
              child: const PlayerPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(PlayerPage), findsOneWidget);
    });
  }
}
