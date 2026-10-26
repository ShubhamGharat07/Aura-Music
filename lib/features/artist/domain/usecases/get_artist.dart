import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/artist/domain/repositories/artist_repository.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

/// Loads a full artist page by id (PRD S10).

/// Returns an empty-id failure for a blank [id].
final class GetArtist implements UseCase<ArtistDetail, String> {
  /// Creates the use case.
  const GetArtist(this._repository);

  final ArtistRepository _repository;

  @override
  Future<Either<Failure, ArtistDetail>> call(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Left(UnknownFailure('Missing artist id')));
    }
    return _repository.artist(trimmed);
  }
}
