import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads the songs behind one language chip (PRD S03).

/// Returns tracks curated for [CatalogLanguage].
final class GetLanguageTracks implements UseCase<List<Track>, CatalogLanguage> {
  /// Creates the use case.
  const GetLanguageTracks(this._repository);

  final HomeRepository _repository;

  static const int _limit = 20;

  @override
  Future<Either<Failure, List<Track>>> call(CatalogLanguage language) =>
      _repository.byLanguage(language, limit: _limit);
}
