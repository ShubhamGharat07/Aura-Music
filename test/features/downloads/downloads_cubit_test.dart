import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/downloads/domain/usecases/download_track.dart';
import 'package:aura_music/features/downloads/domain/usecases/pause_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/remove_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/resume_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/retry_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/watch_downloads.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockRepository extends Mock implements DownloadsRepository {}

void main() {
  late _MockRepository repository;
  late StreamController<List<Download>> controller;
  late DownloadsCubit cubit;

  const track = Track(
    id: 'audius:1',
    title: 'Neon Horizon',
    artist: 'Aurora Skies',
  );
  const entity = Download(
    track: track,
    status: DownloadStatus.completed,
    filePath: '/x',
  );

  setUpAll(() {
    registerFallbackValue(const Track(id: 'fallback', title: 'F', artist: 'x'));
  });

  setUp(() {
    repository = _MockRepository();
    controller = StreamController<List<Download>>.broadcast();
    when(() => repository.watchAll()).thenAnswer((_) => controller.stream);
    cubit = DownloadsCubit(
      WatchDownloads(repository),
      DownloadTrack(repository),
      RemoveDownload(repository),
      PauseDownload(repository),
      ResumeDownload(repository),
      RetryDownload(repository),
    );
    addTearDown(cubit.close);
  });

  tearDown(() => controller.close());

  test('starts in loading', () {
    expect(cubit.state.status, DownloadsStatus.loading);
  });

  test('emits ready when downloads arrive', () async {
    controller.add([entity]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, DownloadsStatus.ready);
    expect(cubit.state.downloads.single, entity);
  });

  test('emits empty when the list is empty', () async {
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, DownloadsStatus.empty);
  });

  test('surfaces a failed download action', () async {
    when(
      () => repository.enqueue(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await cubit.download(track);

    expect(cubit.state.status, DownloadsStatus.error);
    expect(cubit.state.error, 'offline');
  });

  test('delegates removal', () async {
    when(
      () => repository.remove(any()),
    ).thenAnswer((_) async => const Right(unit));

    await cubit.remove('audius:1');

    verify(() => repository.remove('audius:1')).called(1);
  });

  test('pauses active work offline and resumes it online', () async {
    when(
      () => repository.pause(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.resume(any()),
    ).thenAnswer((_) async => const Right(unit));

    controller.add([
      const Download(track: track, status: DownloadStatus.downloading),
    ]);
    await Future<void>.delayed(Duration.zero);

    await cubit.onConnectivityChanged(false);
    verify(() => repository.pause('audius:1')).called(1);

    await cubit.onConnectivityChanged(true);
    verify(() => repository.resume('audius:1')).called(1);
  });

  test('never auto-resumes a download the user paused', () async {
    controller.add([
      const Download(track: track, status: DownloadStatus.paused),
    ]);
    await Future<void>.delayed(Duration.zero);

    await cubit.onConnectivityChanged(true);

    verifyNever(() => repository.resume(any()));
  });
}
