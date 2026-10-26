import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

/// Loads a full album by id (PRD S09).

/// Returns an empty-id failure for a blank [id].
final class GetAlbum implements UseCase<AlbumDetail, String> {
  /// Creates the use case.
  const GetAlbum(this._repository);

  final AlbumRepository _repository;

  @override
  Future<Either<Failure, AlbumDetail>> call(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Left(UnknownFailure('Missing album id')));
    }
    return _repository.album(trimmed);
  }
}
