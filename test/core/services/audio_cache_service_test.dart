import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/audio_cache_service.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

import '../../helpers/fake_dio.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_cache_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  AudioCacheService serviceWith(FakeHttpAdapter adapter) =>
      AudioCacheService(
        dioWithAdapter(adapter, baseUrl: 'https://example.com'),
        directoryProvider: () async => tempDir,
      );

  const track = Track(
    id: 'jiosaavn:test_song_1',
    title: 'Test Song',
    artist: 'Test Artist',
  );

  test('get returns null when track is not cached', () async {
    final adapter = FakeHttpAdapter(
      (_) async => throw StateError('no request expected'),
    );

    final path = await serviceWith(adapter).get(track.id);

    expect(path, isNull);
  });

  test('cacheTrack downloads stream into cache and get returns the file path', () async {
    // Generate dummy audio bytes > 1024 bytes
    final dummyBytes = Uint8List(2048);
    final adapter = FakeHttpAdapter(
      (options) async => ResponseBody.fromBytes(dummyBytes, 200),
    );

    final service = serviceWith(adapter);

    await service.cacheTrack(
      track,
      streamUrl: 'https://example.com/audio.mp4',
    );

    final cachedPath = await service.get(track.id);
    expect(cachedPath, isNotNull);
    expect(File(cachedPath!).existsSync(), isTrue);
    expect(await File(cachedPath).length(), 2048);
    expect(await service.getCacheSizeBytes(), 2048);
  });

  test('clearCache removes all cached audio files', () async {
    final dummyBytes = Uint8List(2048);
    final adapter = FakeHttpAdapter(
      (options) async => ResponseBody.fromBytes(dummyBytes, 200),
    );

    final service = serviceWith(adapter);

    await service.cacheTrack(
      track,
      streamUrl: 'https://example.com/audio.mp4',
    );

    expect(await service.get(track.id), isNotNull);

    await service.clearCache();

    expect(await service.get(track.id), isNull);
    expect(await service.getCacheSizeBytes(), 0);
  });
}
