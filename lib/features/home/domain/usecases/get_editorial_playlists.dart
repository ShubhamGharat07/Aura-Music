import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';

/// Loads the editorially curated playlists shown on home (PRD S03).

/// Returns the editor's pick playlists.
final class GetEditorialPlaylists
    implements UseCase<List<Playlist>, NoParams> {
  /// Creates the use case.
  const GetEditorialPlaylists(this._repository);

  final HomeRepository _repository;

  static const int _limit = 12;

  @override
  Future<Either<Failure, List<Playlist>>> call(NoParams params) =>
      _repository.editorialPlaylists(limit: _limit);
}
