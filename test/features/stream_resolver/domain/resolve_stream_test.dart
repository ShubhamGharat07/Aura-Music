import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

final class _StubRepository implements StreamRepository {
  @override
  Future<Either<Failure, String>> resolve(Track track) async =>
      Right('https://cdn/${track.id}.mp4');
}

void main() {
  test('delegates resolution to the repository', () async {
    final result = await ResolveStream(_StubRepository())(
      const Track(id: 'jiosaavn:abc', title: 'T', artist: 'A'),
    );

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => ''), 'https://cdn/jiosaavn:abc.mp4');
  });
}
