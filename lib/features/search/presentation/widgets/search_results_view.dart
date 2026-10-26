import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/media_card.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';

/// Grouped results honouring the active filter (PRD S05): Songs, Albums,
/// Artists and Playlists sections.

/// Renders [state]'s results for [SearchState.filter].
final class SearchResultsView extends StatelessWidget {
  /// Creates the results view.
  const SearchResultsView({
    super.key,
    required this.state,
    required this.onPlay,
  });

  /// Current search state.
  final SearchState state;

  /// Plays [tracks] from [index].
  final void Function(List<Track> tracks, int index) onPlay;

  bool _visible(SearchFilter filter) =>
      state.filter == SearchFilter.all || state.filter == filter;

  @override
  Widget build(BuildContext context) {
    final results = state.results;
    if (results.isEmpty) {
      return StateView(
        kind: StateKind.empty,
        message: 'No results for "${state.query}"',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            if (state.filter == SearchFilter.all && results.songs.isNotEmpty)
              SliverToBoxAdapter(
                child: _TopResultCard(
                  track: results.songs.first,
                  onTap: () => onPlay(results.songs, 0),
                ),
              ),
            if (_visible(SearchFilter.songs) && results.songs.isNotEmpty)
              ..._songs(),
            if (_visible(SearchFilter.albums) && results.albums.isNotEmpty)
              ..._media(
                'Albums',
                results.albums.length,
                constraints.maxWidth,
                (i) => MediaCard(
                  title: results.albums[i].title,
                  subtitle: results.albums[i].artist,
                  artUrl: results.albums[i].artUrl,
                  onTap: () => context.push(
                    '${AppRoutes.album}/${results.albums[i].id}',
                  ),
                ),
              ),
            if (_visible(SearchFilter.artists) && results.artists.isNotEmpty)
              ..._media(
                'Artists',
                results.artists.length,
                constraints.maxWidth,
                (i) => MediaCard(
                  title: results.artists[i].name,
                  subtitle: results.artists[i].role ?? 'Artist',
                  artUrl: results.artists[i].imageUrl,
                  onTap: () => context.push(
                    '${AppRoutes.artist}/${results.artists[i].id}',
                  ),
                ),
              ),
            if (_visible(SearchFilter.playlists) &&
                results.playlists.isNotEmpty)
              ..._media(
                'Playlists',
                results.playlists.length,
                constraints.maxWidth,
                (i) => MediaCard(
                  title: results.playlists[i].title,
                  subtitle: results.playlists[i].subtitle ?? 'Playlist',
                  artUrl: results.playlists[i].artUrl,
                  onTap: () => context.push(
                    '${AppRoutes.playlist}/${results.playlists[i].id}',
                  ),
                ),
              ),
            // Same end clearance as the idle view.
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 16.w,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _songs() => <Widget>[
    SliverToBoxAdapter(child: SectionHeader(title: 'Songs')),
    SliverList.builder(
      itemCount: state.results.songs.length,
      itemBuilder: (context, i) {
        final track = state.results.songs[i];
        return Padding(
          padding: EdgeInsets.only(bottom: 8.w),
          child: SongTile(
            title: track.title,
            subtitle: track.subtitle,
            artUrl: track.artUrl,
            track: track,
            onTap: () => onPlay(state.results.songs, i),
          ),
        );
      },
    ),
  ];

  List<Widget> _media(
    String title,
    int count,
    double width,
    Widget Function(int) build,
  ) => <Widget>[
    SliverToBoxAdapter(child: SectionHeader(title: title)),
    SliverGrid(
      gridDelegate: AdaptiveGrid.delegate(
        availableWidth: width,
        targetCardWidth: 150,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => build(i),
        childCount: count,
      ),
    ),
  ];
}

/// Hero card for the best song match (PRD S05), shown for the "All" filter.
final class _TopResultCard extends StatelessWidget {
  const _TopResultCard({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final art = 56.w;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: GlassSurface.fake(
        borderRadius: AppRadius.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.art),
                  child: track.artUrl == null
                      ? SizedBox(
                          width: art,
                          height: art,
                          child: const Icon(Icons.music_note),
                        )
                      : CachedNetworkImage(
                          imageUrl: track.artUrl!,
                          width: art,
                          height: art,
                          memCacheWidth: 112,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => SizedBox(
                            width: art,
                            height: art,
                            child: const Icon(Icons.music_note),
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOP RESULT',
                        style: AppTypography.overline.copyWith(color: accent),
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        track.title,
                        style: AppTypography.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        track.artist,
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_circle_fill_rounded, size: 34.r, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
