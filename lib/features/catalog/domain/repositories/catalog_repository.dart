import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Catalog data contract (domain layer). Implemented in `data/` on top of
/// the JioSaavn public API; the presentation layer only ever sees [Track]s.

/// Reads the music catalog feed. Search lives in the `search` feature.
abstract interface class CatalogRepository {
  /// Trending tracks for the home feed.
  Future<Either<Failure, List<Track>>> trending({int limit});
}
