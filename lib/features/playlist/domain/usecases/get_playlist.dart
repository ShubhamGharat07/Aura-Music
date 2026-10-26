import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/playlist/domain/repositories/playlist_repository.dart';

/// Loads a full playlist by id (PRD S11).

/// Returns an empty-id failure for a blank [id].
final class GetPlaylist implements UseCase<PlaylistDetail, String> {
  /// Creates the use case.
  const GetPlaylist(this._repository);

  final PlaylistRepository _repository;

  @override
  Future<Either<Failure, PlaylistDetail>> call(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Left(UnknownFailure('Missing playlist id')));
    }
    return _repository.playlist(trimmed);
  }
}
