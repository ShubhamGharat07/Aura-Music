import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';
import 'package:aura_music/features/podcast/domain/repositories/podcast_repository.dart';

/// [PodcastRepository] implementation using [JiosaavnRemoteDataSource].
final class PodcastRepositoryImpl implements PodcastRepository {
  /// Creates the repository.
  const PodcastRepositoryImpl(this._remote);

  final JiosaavnRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<PodcastShow>>> getTopPodcasts({
    int limit = 20,
    int page = 1,
  }) =>
      guardRemote(() => _remote.topPodcasts(limit: limit, page: page));

  @override
  Future<Either<Failure, List<PodcastShow>>> searchPodcasts(
    String query, {
    int limit = 20,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const Right(<PodcastShow>[]));
    return guardRemote(() => _remote.searchPodcasts(trimmed, limit: limit));
  }

  @override
  Future<Either<Failure, List<PodcastEpisode>>> getPodcastEpisodes(
    String showId, {
    int season = 1,
    int page = 1,
    int limit = 30,
  }) =>
      guardRemote(
        () => _remote.podcastEpisodes(
          showId,
          season: season,
          page: page,
          limit: limit,
        ),
      );
}
