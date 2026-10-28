import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/library/presentation/bloc/library_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/library_collections.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Liked + discover sections and the master-detail collection detail pane.

/// Liked-songs section (live from the local database).
final class LikedSection extends StatelessWidget {
  /// Creates the liked section.
  const LikedSection({super.key, required this.scrollable, this.limit});

  /// Render inside a scroll view vs. a fixed column.
  final bool scrollable;

  /// Maximum inline rows (null = all). Compact library shows a short preview.
  final int? limit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedTracksCubit, LikedTracksState>(
      builder: (context, state) {
        final tracks = state.tracks;
        final visible = limit == null ? tracks : tracks.take(limit!).toList();
        final children = <Widget>[
          SectionHeader(
            title: tracks.isEmpty
                ? 'Liked songs'
                : 'Liked songs · ${tracks.length}',
            onSeeAll: tracks.isEmpty ? null : () => _openLikedPage(context),
          ),
          if (tracks.isEmpty)
            const _EmptyHint(
              icon: Icons.favorite_border_rounded,
              message: 'Tap the heart on any track to save it here.',
            )
          else
            for (var i = 0; i < visible.length; i++)
              Padding(
                padding: EdgeInsets.only(top: 8.w),
                child: _TrackRow(
                  track: visible[i],
                  onTap: () => playFromCatalog(context, tracks, i),
                ),
              ),
        ];
        return _SectionBody(scrollable: scrollable, children: children);
      },
    );
  }

  void _openLikedPage(BuildContext context) => context.push(AppRoutes.liked);
}

/// Discover / made-for-you section (catalog).
final class DiscoverSection extends StatelessWidget {
  /// Creates the discover section.
  const DiscoverSection({super.key, required this.scrollable, this.limit});

  /// Render inside a scroll view vs. a fixed column.
  final bool scrollable;

  /// Maximum inline rows (null = all).
  final int? limit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        if (state.status == LibraryStatus.loading && state.discover.isEmpty) {
          return const StateView(kind: StateKind.loading, message: 'Loading…');
        }
        if (state.status == LibraryStatus.error && state.discover.isEmpty) {
          return StateView(
            kind: StateKind.error,
            message: state.error ?? 'Could not load',
            onRetry: () => context.read<LibraryCubit>().load(),
          );
        }
        final all = state.discover;
        final tracks = limit == null ? all : all.take(limit!).toList();
        return _SectionBody(
          scrollable: scrollable,
          children: [
            const SectionHeader(title: 'Discover'),
            if (all.isEmpty)
              const _EmptyHint(
                icon: Icons.explore_outlined,
                message: 'Fresh picks will appear here.',
              )
            else
              for (var i = 0; i < tracks.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: 8.w),
                  child: _TrackRow(
                    track: tracks[i],
                    onTap: () => playFromCatalog(context, all, i),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Detail pane for a selected album/artist collection (expanded).
final class CollectionDetail extends StatelessWidget {
  /// Creates the detail pane.
  const CollectionDetail({super.key, required this.collection});

  /// The selected collection.
  final LibraryCollection collection;

  @override
  Widget build(BuildContext context) {
    final tracks = collection.tracks;
    final children = <Widget>[
      Text(collection.title, style: AppTypography.display),
      SizedBox(height: 4.w),
      Text(collection.subtitle, style: AppTypography.caption),
      SizedBox(height: 12.w),
      Wrap(
        spacing: 8.w,
        children: [
          FilledButton.icon(
            onPressed: tracks.isEmpty
                ? null
                : () => playFromCatalog(context, tracks, 0),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
          OutlinedButton.icon(
            onPressed: tracks.isEmpty ? null : () => _shuffle(context, tracks),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
          ),
        ],
      ),
      SizedBox(height: 12.w),
      for (var i = 0; i < tracks.length; i++)
        Padding(
          padding: EdgeInsets.only(top: 8.w),
          child: _TrackRow(
            track: tracks[i],
            onTap: () => playFromCatalog(context, tracks, i),
          ),
        ),
    ];
    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  void _shuffle(BuildContext context, List<Track> tracks) =>
      playFromCatalog(context, tracks, Random().nextInt(tracks.length));
}

final class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SongTile(
      title: track.title,
      subtitle: track.artist,
      artUrl: track.artUrl,
      track: track,
      onTap: onTap,
    );
  }
}

final class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.w),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: AppColors.textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.scrollable, required this.children});

  final bool scrollable;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
}
