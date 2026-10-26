import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_source.dart';

/// [StreamRepository] implementation: walks its [StreamSource]s in order and
/// returns the first URL produced (PRD F01 fallback chain).

/// Ordered fallback-chain resolver.
final class StreamRepositoryImpl implements StreamRepository {
  /// Creates the repository from an ordered source chain.
  const StreamRepositoryImpl(this._sources);

  final List<StreamSource> _sources;

  @override
  Future<Either<Failure, String>> resolve(Track track) async {
    AppException? lastError;
    for (final source in _sources) {
      try {
        final url = await source.resolve(track);
        if (url != null && url.isNotEmpty) return Right(url);
      } on AppException catch (error) {
        lastError = error;
      }
    }
    return Left(_failure(lastError));
  }

  Failure _failure(AppException? error) => switch (error) {
    NetworkException e => NetworkFailure(e.message),
    ServerException e => ServerFailure(e.message),
    StreamResolveException e => StreamFailure(e.message),
    AppException e => UnknownFailure(e.message),
    null => const StreamFailure('No stream source could resolve this track'),
  };
}
