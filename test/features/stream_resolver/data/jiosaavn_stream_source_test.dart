import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/des_ecb.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/data/datasources/jiosaavn_stream_source.dart';

import '../../../helpers/fake_dio.dart';

/// Encrypts [plain] the way JioSaavn serves `encrypted_media_url`.
String encrypted(String plain) {
  const key = '38346591';
  final bytes = Uint8List.fromList(utf8.encode(plain));
  final pad = 8 - (bytes.length % 8);
  final padded = Uint8List(bytes.length + pad)
    ..setRange(0, bytes.length, bytes);
  for (var i = bytes.length; i < padded.length; i++) {
    padded[i] = pad;
  }
  return base64.encode(
    DesEcb.encryptBytes(padded, Uint8List.fromList(utf8.encode(key))),
  );
}

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  JiosaavnStreamSource sourceWith(FakeHttpAdapter adapter) =>
      JiosaavnStreamSource(
        JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
      );

  test('refreshes an inline URL (catalog URLs expire)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'songs': [
          {
            'id': 'abc',
            'more_info': {
              'encrypted_media_url': encrypted(
                'https://aac.saavncdn.com/9/fresh_320.mp4',
              ),
              '320kbps': 'true',
            },
          },
        ],
      }),
    );
    const track = Track(
      id: 'jiosaavn:abc',
      title: 'T',
      artist: 'A',
      streamUrl: 'https://cdn/stale_320.mp4',
    );

    expect(
      await sourceWith(adapter).resolve(track),
      'https://aac.saavncdn.com/9/fresh_320.mp4',
    );
    expect(adapter.requests, hasLength(1));
  });

  test('declines non-JioSaavn ids', () async {
    final adapter = FakeHttpAdapter(
      (_) async => throw StateError('no request expected'),
    );
    const track = Track(id: 'youtube:xyz', title: 'T', artist: 'A');

    expect(await sourceWith(adapter).resolve(track), isNull);
    expect(adapter.requests, isEmpty);
  });

  test('resolves a missing URL via song.getDetails', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'songs': [
          {
            'id': 'abc',
            'more_info': {
              'encrypted_media_url': encrypted(
                'https://aac.saavncdn.com/9/song_96.mp4',
              ),
              '320kbps': 'true',
            },
          },
        ],
      }),
    );

    final url = await sourceWith(
      adapter,
    ).resolve(const Track(id: 'jiosaavn:abc', title: 'T', artist: 'A'));

    expect(url, 'https://aac.saavncdn.com/9/song_320.mp4');
    expect(
      adapter.requests.single.queryParameters['__call'],
      'song.getDetails',
    );
    expect(adapter.requests.single.queryParameters['pids'], 'abc');
  });

  test('requests 160 kbps when 320 is unavailable', () async {
    final adapter = FakeHttpAdapter(
      (_) async => jsonResponse({
        'songs': [
          {
            'id': 'abc',
            'more_info': {
              'encrypted_media_url': encrypted(
                'https://aac.saavncdn.com/9/song_96.mp4',
              ),
              '320kbps': 'false',
            },
          },
        ],
      }),
    );

    final url = await sourceWith(
      adapter,
    ).resolve(const Track(id: 'jiosaavn:abc', title: 'T', artist: 'A'));

    expect(url, 'https://aac.saavncdn.com/9/song_160.mp4');
  });

  test('returns null when the song has no media URL', () async {
    final adapter = FakeHttpAdapter((_) async => jsonResponse({'songs': []}));
    expect(
      await sourceWith(
        adapter,
      ).resolve(const Track(id: 'jiosaavn:z', title: 'T', artist: 'A')),
      isNull,
    );
  });
}
