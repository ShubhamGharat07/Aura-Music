import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/downloads_dao.dart';
import 'package:aura_music/features/downloads/data/datasources/download_engine.dart';
import 'package:aura_music/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _FakeEngine implements DownloadEngine {
  _FakeEngine(this.dir, {this.failure});

  final Directory dir;
  final AppException? failure;

  @override
  Future<String> pathFor(String fileName) async => p.join(dir.path, fileName);

  @override
  Stream<DownloadChunk> download({
    required String url,
    required String fileName,
    CancelToken? cancelToken,
  }) async* {
    if (failure != null) throw failure!;
    final path = await pathFor(fileName);
    File(path).writeAsStringSync('audio-bytes');
    yield DownloadChunk(received: 100, total: 100, path: path);
  }
}

void main() {
  late AppDatabase db;
  late Directory temp;

  const track = Track(
    id: 'audius:1',
    title: 'Neon Horizon',
    artist: 'Aurora Skies',
    streamUrl: 'https://cdn/stream/1',
  );

  DownloadsRepositoryImpl repo(AppException? failure) =>
      DownloadsRepositoryImpl(
        DownloadsDao(db),
        _FakeEngine(temp, failure: failure),
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    temp = Directory.systemTemp.createTempSync('aura_dl_test');
  });

  tearDown(() {
    db.close();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('enqueue completes and stores a playable local file', () async {
    final result = await repo(null).enqueue(track);

    expect(result.isRight(), isTrue);
    final all = await repo(null).all();
    expect(all.single.status, DownloadStatus.completed);
    expect(all.single.isComplete, isTrue);

    final local = await repo(null).localFileFor(track.id);
    expect(local.isRight(), isTrue);
    expect(local.getOrElse((_) => null), isNotNull);
  });

  test('enqueue without a stream URL marks failed', () async {
    const noUrl = Track(id: 'audius:2', title: 'X', artist: 'Y');
    final result = await repo(null).enqueue(noUrl);

    expect(result.isLeft(), isTrue);
    final all = await repo(null).all();
    expect(all.single.status, DownloadStatus.failed);
    expect(all.single.error, 'No stream URL');
  });

  test('enqueue maps engine failure to a failed row', () async {
    final result = await repo(const NetworkException('offline')).enqueue(track);

    expect(result.isLeft(), isTrue);
    final all = await repo(null).all();
    expect(all.single.status, DownloadStatus.failed);
    expect(all.single.error, 'offline');
  });

  test('remove deletes the row and its file', () async {
    final repository = repo(null);
    await repository.enqueue(track);
    final path = (await repository.localFileFor(
      track.id,
    )).getOrElse((_) => null)!;
    expect(File(path).existsSync(), isTrue);

    await repository.remove(track.id);

    expect(await repository.all(), isEmpty);
    expect(File(path).existsSync(), isFalse);
  });

  test('watchAll emits after an enqueue', () async {
    final repository = repo(null);
    final emissions = <List<Download>>[];
    final sub = repository.watchAll().listen(emissions.add);

    await repository.enqueue(track);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(emissions.last.single.status, DownloadStatus.completed);
  });
}
