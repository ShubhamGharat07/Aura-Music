import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';
import 'package:aura_music/features/podcast/domain/repositories/podcast_repository.dart';

/// Fetches top podcast shows for feed and discovery.
final class GetTopPodcasts implements UseCase<List<PodcastShow>, int> {
  /// Creates the use case.
  const GetTopPodcasts(this._repository);

  final PodcastRepository _repository;

  @override
  Future<Either<Failure, List<PodcastShow>>> call(int limit) =>
      _repository.getTopPodcasts(limit: limit);
}
