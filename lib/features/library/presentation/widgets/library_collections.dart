import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
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
    if (create && rows.isEmpty) {
      return _NewPlaylistBanner(onTap: () => createLibraryPlaylist(context));
    }
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
              SizedBox(width: width, height: width / 0.74, child: card),
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
            Expanded(
              child: Text(
                'Collections',
                style: AppTypography.title.copyWith(
                  fontSize: 18.5.sp,
                  letterSpacing: -0.45,
                ),
              ),
            ),
            _ToolButton(
              tooltip: library.view == LibraryView.grid
                  ? 'List view'
                  : 'Grid view',
              icon: library.view == LibraryView.grid
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              onTap: cubit.toggleView,
            ),
            SizedBox(width: 2.w),
            _ToolButton(
              tooltip: library.sort == LibrarySortOrder.recent
                  ? 'Sort: Recently added'
                  : 'Sort: Title',
              icon: Icons.sort_rounded,
              onTap: cubit.cycleSort,
            ),
          ],
        ),
        SizedBox(height: 8.w),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in LibraryFilter.values) ...[
                if (filter != LibraryFilter.values.first) SizedBox(width: 18.w),
                _FilterTab(
                  label: _filterLabel(filter),
                  selected: library.filter == filter,
                  onTap: () => cubit.selectFilter(filter),
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

final class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: Size(38.w, 38.w),
        padding: EdgeInsets.zero,
        foregroundColor: AppColors.textSecondary,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 20.r),
    );
  }
}

final class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 5.w),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: AppDurations.fast,
                curve: AppCurves.out,
                child: Container(
                  width: 16.w,
                  height: 2.w,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _NewPlaylistBanner extends StatelessWidget {
  const _NewPlaylistBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.glassBorder, width: 0.6),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
            child: Row(
              children: [
                SizedBox(
                  width: 34.w,
                  child: Icon(
                    Icons.add_rounded,
                    size: 24.r,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your first playlist',
                        style: AppTypography.subtitle,
                      ),
                      SizedBox(height: 2.w),
                      Text(
                        'Group the songs you keep coming back to.',
                        style: AppTypography.caption.copyWith(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.r,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _NewPlaylistCard extends StatelessWidget {
  const _NewPlaylistCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.art),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bgElevated.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadius.art),
            border: Border.all(color: AppColors.glassBorder, width: 0.6),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(9.r),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.14),
                        width: 0.7,
                      ),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 30.r,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8.w),
                Text(
                  'New playlist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle,
                ),
                SizedBox(height: 1.w),
                Text('Create', style: AppTypography.caption),
              ],
            ),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7.w, horizontal: 4.w),
          child: Row(
            children: [
              SizedBox(
                width: 22.w,
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.textPrimary,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New playlist', style: AppTypography.subtitle),
                    SizedBox(height: 1.w),
                    Text('Create a playlist', style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.r,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
