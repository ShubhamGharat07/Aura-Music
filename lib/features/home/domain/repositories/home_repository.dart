import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Home feed sections (PRD S03). Each section is fetched on its own so the
/// UI can load them independently. Composed over the JioSaavn catalog.

/// Home feed data contract (domain layer).
abstract interface class HomeRepository {
  /// Quick picks + trending tracks.
  Future<Either<Failure, List<Track>>> trending({int limit});

  /// Freshly released tracks.
  Future<Either<Failure, List<Track>>> newReleases({int limit});

  /// Tracks similar to [artist] ("Because you listened to X").
  Future<Either<Failure, List<Track>>> byArtist(String artist, {int limit});

  /// Mood / genre filters offered by the catalog (most relevant first).
  Future<Either<Failure, List<Genre>>> genres();

  /// Up to [limit] tracks curated for [genre].
  Future<Either<Failure, List<Track>>> byGenre(Genre genre, {int limit});

  /// Up to [limit] tracks curated for [language].
  Future<Either<Failure, List<Track>>> byLanguage(
    CatalogLanguage language, {
    int limit,
  });

  /// Latest album releases (singles filtered out).
  Future<Either<Failure, List<Album>>> newAlbums({int limit});

  /// Trending albums (singles and playlists filtered out).
  Future<Either<Failure, List<Album>>> trendingAlbums({int limit});

  /// Popular artists for the home artist row.
  Future<Either<Failure, List<Artist>>> popularArtists({int limit});
}
