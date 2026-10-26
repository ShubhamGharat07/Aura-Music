import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/domain/entities/search_results.dart';

/// Search data contract (domain layer). Implemented in `data/` over the
/// JioSaavn public API; presentation only sees [SearchResults] / [Track].

/// Reads search results and type-ahead suggestions.
abstract interface class SearchRepository {
  /// Full multi-type search for [query] (blank yields empty groups).
  Future<Either<Failure, SearchResults>> search(String query);

  /// Lightweight song suggestions for [query] (type-ahead, S04).
  Future<Either<Failure, List<Track>>> suggestions(String query, {int limit});

  /// Ranked top songs for the idle "Suggestions" list (S04). Real catalog data
  /// ordered by lifetime play count, so the empty search screen is never a
  /// hard-coded list.
  Future<Either<Failure, List<Track>>> browse({int limit});
}
