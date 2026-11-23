import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';
import 'package:aura_music/features/podcast/domain/repositories/podcast_repository.dart';

/// Parameters for fetching podcast episodes.
final class GetPodcastEpisodesParams extends Equatable {
  const GetPodcastEpisodesParams({
    required this.showId,
    this.season = 1,
    this.page = 1,
    this.limit = 30,
  });

  final String showId;
  final int season;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [showId, season, page, limit];
}

/// Fetches episodes of a podcast show.
final class GetPodcastEpisodes
    implements UseCase<List<PodcastEpisode>, GetPodcastEpisodesParams> {
  /// Creates the use case.
  const GetPodcastEpisodes(this._repository);

  final PodcastRepository _repository;

  @override
  Future<Either<Failure, List<PodcastEpisode>>> call(
    GetPodcastEpisodesParams params,
  ) =>
      _repository.getPodcastEpisodes(
        params.showId,
        season: params.season,
        page: params.page,
        limit: params.limit,
      );
}
