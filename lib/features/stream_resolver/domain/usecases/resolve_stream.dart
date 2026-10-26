import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';

/// Resolves a track to a playable audio URL (PRD F01).

/// Resolves a playable stream URL for one track.
final class ResolveStream implements UseCase<String, Track> {
  /// Creates the use case.
  const ResolveStream(this._repository);

  final StreamRepository _repository;

  @override
  Future<Either<Failure, String>> call(Track params) =>
      _repository.resolve(params);
}
