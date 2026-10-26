import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [CatalogRepository] implementation. Maps data-layer [AppException]s at the
/// boundary via [guardRemote].

/// JioSaavn-backed catalog repository.
final class CatalogRepositoryImpl implements CatalogRepository {
  /// Creates the repository.
  const CatalogRepositoryImpl(this._remote);

  final JiosaavnRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Track>>> trending({int limit = 40}) =>
      guardRemote(() => _remote.trending(limit: limit));
}
