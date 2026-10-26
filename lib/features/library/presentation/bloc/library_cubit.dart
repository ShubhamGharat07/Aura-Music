import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/catalog/domain/usecases/get_trending_tracks.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Library discover feed + collections view state (PRD S12). Liked songs are
/// handled by `LikedTracksCubit`; playlists by `PlaylistsCubit`.

/// Library load status.
enum LibraryStatus {
  /// Fetch in flight.
  loading,

  /// Ready.
  ready,

  /// Fetch failed.
  error,
}

/// Collection filter chip (PRD S12: Playlists · Albums · Artists).
enum LibraryFilter {
  /// User playlists.
  playlists,

  /// Albums derived from liked songs.
  albums,

  /// Artists derived from liked songs.
  artists,
}

/// Collections layout (PRD S12 grid/list toggle).
enum LibraryView {
  /// Grid of cards.
  grid,

  /// Vertical list.
  list,
}

/// Collections ordering (PRD S12 sort).
enum LibrarySortOrder {
  /// Most recent first.
  recent,

  /// Title A–Z.
  title,
}

/// Immutable library state.
final class LibraryState extends Equatable {
  /// Creates the state.
  const LibraryState({
    this.status = LibraryStatus.loading,
    this.discover = const [],
    this.error,
    this.filter = LibraryFilter.playlists,
    this.view = LibraryView.grid,
    this.sort = LibrarySortOrder.recent,
    this.selectedId,
  });

  /// Current status.
  final LibraryStatus status;

  /// Discover / made-for-you tracks.
  final List<Track> discover;

  /// Error message (when [status] is [LibraryStatus.error]).
  final String? error;

  /// Active collection filter chip.
  final LibraryFilter filter;

  /// Collections layout.
  final LibraryView view;

  /// Collections ordering.
  final LibrarySortOrder sort;

  /// Selected collection id (expanded master-detail only).
  final String? selectedId;

  static const Object _unset = Object();

  /// Copies with overrides. Pass [selectedId] a value (including null) to set
  /// it; omit it to keep the current selection.
  LibraryState copyWith({
    LibraryStatus? status,
    List<Track>? discover,
    String? error,
    LibraryFilter? filter,
    LibraryView? view,
    LibrarySortOrder? sort,
    Object? selectedId = _unset,
  }) {
    return LibraryState(
      status: status ?? this.status,
      discover: discover ?? this.discover,
      error: error,
      filter: filter ?? this.filter,
      view: view ?? this.view,
      sort: sort ?? this.sort,
      selectedId: identical(selectedId, _unset)
          ? this.selectedId
          : selectedId as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    discover,
    error,
    filter,
    view,
    sort,
    selectedId,
  ];
}

/// Loads the discover feed and owns the collections view state (PRD S12).
final class LibraryCubit extends Cubit<LibraryState> {
  /// Creates the cubit.
  LibraryCubit(this._getTrending) : super(const LibraryState());

  final GetTrendingTracks _getTrending;

  /// Loads the discover feed (keeps the collections view state).
  Future<void> load() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    final result = await _getTrending(30);
    result.fold(
      (failure) => emit(
        state.copyWith(status: LibraryStatus.error, error: failure.message),
      ),
      (tracks) =>
          emit(state.copyWith(status: LibraryStatus.ready, discover: tracks)),
    );
  }

  /// Switches the active filter chip (clears any selection).
  void selectFilter(LibraryFilter filter) =>
      emit(state.copyWith(filter: filter, selectedId: null));

  /// Toggles grid ↔ list.
  void toggleView() => emit(
    state.copyWith(
      view: state.view == LibraryView.grid
          ? LibraryView.list
          : LibraryView.grid,
    ),
  );

  /// Cycles recent ↔ title.
  void cycleSort() => emit(
    state.copyWith(
      sort: state.sort == LibrarySortOrder.recent
          ? LibrarySortOrder.title
          : LibrarySortOrder.recent,
    ),
  );

  /// Selects a collection (expanded master-detail); null clears it.
  void select(String? id) => emit(state.copyWith(selectedId: id));
}
