import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/data/repositories/stream_repository_impl.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_source.dart';

final class _Source implements StreamSource {
  _Source(this.name, this._handler);

  @override
  final String name;
  final Future<String?> Function(Track) _handler;
  int calls = 0;

  @override
  Future<String?> resolve(Track track) {
    calls++;
    return _handler(track);
  }
}

void main() {
  const track = Track(id: 'jiosaavn:abc', title: 'T', artist: 'A');

  test('returns the first non-null URL and stops the chain', () async {
    final miss = _Source('a', (_) async => null);
    final hit = _Source('b', (_) async => 'https://cdn/320.mp4');
    final later = _Source('c', (_) async => throw StateError('should not run'));

    final result = await StreamRepositoryImpl([
      miss,
      hit,
      later,
    ]).resolve(track);

    expect(result.getOrElse((_) => ''), 'https://cdn/320.mp4');
    expect(later.calls, 0);
  });

  test('falls through to the next source when one errors', () async {
    final failing = _Source(
      'a',
      (_) async => throw const NetworkException('offline'),
    );
    final hit = _Source('b', (_) async => 'https://cdn/fallback.mp4');

    final result = await StreamRepositoryImpl([failing, hit]).resolve(track);

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => ''), 'https://cdn/fallback.mp4');
  });

  test('returns StreamFailure when every source misses', () async {
    final result = await StreamRepositoryImpl([
      _Source('a', (_) async => null),
      _Source('b', (_) async => null),
    ]).resolve(track);

    result.match(
      (failure) => expect(failure, isA<StreamFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test(
    'maps a network error to NetworkFailure when nothing resolves',
    () async {
      final result = await StreamRepositoryImpl([
        _Source('a', (_) async => throw const NetworkException('offline')),
      ]).resolve(track);

      result.match(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );
}
