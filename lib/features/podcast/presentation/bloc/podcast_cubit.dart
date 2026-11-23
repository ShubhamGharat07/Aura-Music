import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';
import 'package:aura_music/features/podcast/domain/usecases/get_podcast_episodes.dart';

/// Podcast load status.
enum PodcastStatus {
  /// Fetch in flight.
  loading,

  /// Episodes ready.
  ready,

  /// Load failed.
  error,
}

/// Immutable podcast detail state.
final class PodcastState extends Equatable {
  const PodcastState({
    this.status = PodcastStatus.loading,
    this.show,
    this.episodes = const [],
    this.error,
  });

  final PodcastStatus status;
  final PodcastShow? show;
  final List<PodcastEpisode> episodes;
  final String? error;

  @override
  List<Object?> get props => [status, show, episodes, error];
}

/// Cubit managing podcast episode fetching and display.
final class PodcastCubit extends Cubit<PodcastState> {
  PodcastCubit(this._getEpisodes) : super(const PodcastState());

  final GetPodcastEpisodes _getEpisodes;

  int _request = 0;

  /// Loads episodes for [showId] and attaches initial [show] metadata if provided.
  Future<void> load(String showId, {PodcastShow? show, int season = 1}) async {
    final request = ++_request;
    emit(PodcastState(status: PodcastStatus.loading, show: show ?? state.show));

    final result = await _getEpisodes(
      GetPodcastEpisodesParams(showId: showId, season: season),
    );

    if (isClosed || request != _request) return;
    result.fold(
      (failure) => emit(
        PodcastState(
          status: PodcastStatus.error,
          show: show ?? state.show,
          error: failure.message,
        ),
      ),
      (episodes) => emit(
        PodcastState(
          status: PodcastStatus.ready,
          show: show ?? state.show,
          episodes: episodes,
        ),
      ),
    );
  }
}
