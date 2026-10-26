import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/library_collections.dart';
import 'package:aura_music/features/library/presentation/bloc/library_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/collection_card.dart';
import 'package:aura_music/features/library/presentation/widgets/library_shortcuts.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Library collections (PRD S12): filter chips + grid/list + sort.

/// A resolved library collection row (playlist, album or artist).
final class LibraryCollection {
  /// Creates a row.
  const LibraryCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    this.artUrl,
    required this.tracks,
    this.playlistId,
  });

  /// Stable row id.
  final String id;

  /// Row title.
  final String title;

  /// Secondary line.
  final String subtitle;

  /// Cover art URL.
  final String? artUrl;

  /// Tracks (empty for playlists, which open a page).
  final List<Track> tracks;

  /// Playlist id when this row is a user playlist.
  final String? playlistId;

  /// True when this row opens a playlist page.
  bool get isPlaylist => playlistId != null;
}

/// Builds the collection rows for the active filter and sort.
List<LibraryCollection> buildLibraryCollections({
  required LibraryState library,
  required List<Track> liked,
  required List<UserPlaylist> playlists,
}) {
  final rows = switch (library.filter) {
    LibraryFilter.playlists => [
      for (final playlist in playlists)
        LibraryCollection(
          id: 'pl:${playlist.id}',
          title: playlist.name,
          subtitle: playlist.songCount == 1
              ? '1 song'
              : '${playlist.songCount} songs',
          artUrl: playlist.artUrl,
          tracks: const [],
          playlistId: playlist.id,
        ),
    ],
    LibraryFilter.albums => [
      for (final group in groupByAlbum(liked)) _fromGroup(group),
    ],
    LibraryFilter.artists => [
      for (final group in groupByArtist(liked)) _fromGroup(group),
    ],
  };
  final sorted = [...rows];
  if (library.sort == LibrarySortOrder.title) {
    sorted.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
  }
  return List.unmodifiable(sorted);
}

LibraryCollection _fromGroup(TrackCollection group) => LibraryCollection(
  id: group.id,
  title: group.title,
  subtitle:
      group.subtitle ?? (group.count == 1 ? '1 song' : '${group.count} songs'),
  artUrl: group.artUrl,
  tracks: group.tracks,
);

/// Chips + layout toggle + sort + the collections themselves.
final class LibraryCollections extends StatelessWidget {
  /// Creates the collections section.
  const LibraryCollections({
    super.key,
    required this.selectMode,
    this.scrollable = false,
  });

  /// In master-detail (expanded), taps select album/artist rows instead of
  /// playing them.
  final bool selectMode;

  /// Render inside a scroll view (compact) vs. a fixed column.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryCubit>().state;
    final liked = context.watch<LikedTracksCubit>().state.tracks;
    final playlists = context.watch<PlaylistsCubit>().state.playlists;
    final rows = buildLibraryCollections(
      library: library,
      liked: liked,
      playlists: playlists,
    );
    final create = library.filter == LibraryFilter.playlists;
    final children = <Widget>[
      _Controls(library: library),
      SizedBox(height: 12.w),
      if (rows.isEmpty && !create)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24.w),
          child: Row(
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 20.r,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: 8.w),
              Text(switch (library.filter) {
                LibraryFilter.playlists => 'No playlists yet.',
                LibraryFilter.albums => 'Like songs to build albums.',
                LibraryFilter.artists => 'Like songs to build artists.',
              }, style: AppTypography.caption),
            ],
          ),
        )
      else if (library.view == LibraryView.grid)
        _grid(context, rows, create)
      else
        _list(context, rows, create),
    ];
    if (scrollable) {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _grid(
    BuildContext context,
    List<LibraryCollection> rows,
    bool create,
  ) {
    final cards = <Widget>[
      if (create) _NewPlaylistCard(onTap: () => createLibraryPlaylist(context)),
      for (final row in rows)
        CollectionCard(
          title: row.title,
          subtitle: row.subtitle,
          artUrl: row.artUrl,
          onTap: () => _open(context, row),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AdaptiveGrid.columns(
          availableWidth: constraints.maxWidth,
          targetCardWidth: 165,
          maxColumns: 4,
        );
        final width = (constraints.maxWidth - (columns - 1) * 12.w) / columns;
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.w,
          children: [
            for (final card in cards)
              SizedBox(width: width, height: width / 0.78, child: card),
          ],
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<LibraryCollection> rows,
    bool create,
  ) {
    return Column(
      children: [
        if (create)
          Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: _NewPlaylistTile(
              onTap: () => createLibraryPlaylist(context),
            ),
          ),
        for (final row in rows)
          Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: SongTile(
              title: row.title,
              subtitle: row.subtitle,
              artUrl: row.artUrl,
              onTap: () => _open(context, row),
            ),
          ),
      ],
    );
  }

  void _open(BuildContext context, LibraryCollection row) {
    if (row.isPlaylist) {
      context.push('${AppRoutes.playlists}/${row.playlistId}');
      return;
    }
    if (selectMode) {
      context.read<LibraryCubit>().select(row.id);
      return;
    }
    playFromCatalog(context, row.tracks, 0);
  }
}

final class _Controls extends StatelessWidget {
  const _Controls({required this.library});

  final LibraryState library;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Collections', style: AppTypography.title)),
            IconButton(
              tooltip: library.view == LibraryView.grid
                  ? 'List view'
                  : 'Grid view',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                library.view == LibraryView.grid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: cubit.toggleView,
            ),
            IconButton(
              tooltip: library.sort == LibrarySortOrder.recent
                  ? 'Sort: Recently added'
                  : 'Sort: Title',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.sort_rounded),
              onPressed: cubit.cycleSort,
            ),
          ],
        ),
        SizedBox(height: 4.w),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(right: 4.w),
          child: Row(
            children: [
              for (final filter in LibraryFilter.values) ...[
                if (filter != LibraryFilter.values.first) SizedBox(width: 8.w),
                ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: library.filter == filter,
                  onSelected: (_) => cubit.selectFilter(filter),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _filterLabel(LibraryFilter filter) => switch (filter) {
    LibraryFilter.playlists => 'Playlists',
    LibraryFilter.albums => 'Albums',
    LibraryFilter.artists => 'Artists',
  };
}

final class _NewPlaylistCard extends StatelessWidget {
  const _NewPlaylistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassSurface.fake(
      borderRadius: 20.r,
      padding: EdgeInsets.all(10.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.add_rounded, size: 34.r, color: accent),
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              'New playlist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subtitle,
            ),
            Text('Create', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

final class _NewPlaylistTile extends StatelessWidget {
  const _NewPlaylistTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 46.r,
          height: 46.r,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.add_rounded, color: accent),
        ),
        title: Text('New playlist', style: AppTypography.subtitle),
        subtitle: Text('Create a playlist', style: AppTypography.caption),
      ),
    );
  }
}
