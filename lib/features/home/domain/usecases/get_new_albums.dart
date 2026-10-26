import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the album grid sections shown on home (PRD S03).

/// Returns the latest album releases.
final class GetNewAlbums implements UseCase<List<Album>, NoParams> {
  /// Creates the use case.
  const GetNewAlbums(this._repository);

  final HomeRepository _repository;

  static const int _limit = 30;

  @override
  Future<Either<Failure, List<Album>>> call(NoParams params) =>
      _repository.newAlbums(limit: _limit);
}
