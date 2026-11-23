import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';

/// Podcast data contract (domain layer).
abstract interface class PodcastRepository {
  /// Fetches top / trending podcast shows from the catalog.
  Future<Either<Failure, List<PodcastShow>>> getTopPodcasts({
    int limit = 20,
    int page = 1,
  });

  /// Searches for podcast shows matching [query].
  Future<Either<Failure, List<PodcastShow>>> searchPodcasts(
    String query, {
    int limit = 20,
  });

  /// Fetches episodes of a podcast show.
  Future<Either<Failure, List<PodcastEpisode>>> getPodcastEpisodes(
    String showId, {
    int season = 1,
    int page = 1,
    int limit = 30,
  });
}
