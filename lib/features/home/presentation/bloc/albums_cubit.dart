import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_albums.dart';
import 'package:aura_music/features/home/domain/usecases/get_trending_albums.dart';

/// Album browse lists (PRD S03). The home grids only preview a couple of rows;
/// this cubit backs the "See all" pages that show the full list.

/// Which album browse list a page shows.
enum AlbumsKind {
  /// Latest releases (singles filtered out).
  newAlbums('new', 'New albums'),

  /// Albums trending across the catalog.
  trending('trending', 'Trending albums');

  const AlbumsKind(this.slug, this.title);

  /// URL segment for the route.
  final String slug;

  /// Page / section title.
  final String title;

  /// Resolves a route segment, defaulting to [newAlbums] for unknown input.
  static AlbumsKind fromSlug(String slug) => AlbumsKind.values.firstWhere(
    (kind) => kind.slug == slug,
    orElse: () => newAlbums,
  );
}

/// Album list status.
enum AlbumsStatus {
  /// Fetch in flight.
  loading,

  /// Has albums.
  ready,

  /// Loaded but empty.
  empty,

  /// Load failed.
  error,
}

/// Immutable album list state.
final class AlbumsState extends Equatable {
  /// Creates the state.
  const AlbumsState({
    this.kind = AlbumsKind.newAlbums,
    this.status = AlbumsStatus.loading,
    this.albums = const [],
    this.error,
  });

  /// Which list this state describes.
  final AlbumsKind kind;

  /// Current status.
  final AlbumsStatus status;

  /// Loaded albums.
  final List<Album> albums;

  /// Error message when [status] is [AlbumsStatus.error].
  final String? error;

  @override
  List<Object?> get props => [kind, status, albums, error];
}

/// Loads one album browse list.
final class AlbumsCubit extends Cubit<AlbumsState> {
  /// Creates the cubit.
  AlbumsCubit(this._getNewAlbums, this._getTrendingAlbums)
    : super(const AlbumsState());

  final GetNewAlbums _getNewAlbums;
  final GetTrendingAlbums _getTrendingAlbums;

  int _generation = 0;

  /// Loads (or reloads) [kind].
  Future<void> load(AlbumsKind kind) async {
    final generation = ++_generation;
    emit(AlbumsState(kind: kind));
    final result = kind == AlbumsKind.newAlbums
        ? await _getNewAlbums(const NoParams())
        : await _getTrendingAlbums(const NoParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(
        AlbumsState(
          kind: kind,
          status: AlbumsStatus.error,
          error: failure.message,
        ),
      ),
      (albums) => emit(
        AlbumsState(
          kind: kind,
          status: albums.isEmpty ? AlbumsStatus.empty : AlbumsStatus.ready,
          albums: albums,
        ),
      ),
    );
  }
}
