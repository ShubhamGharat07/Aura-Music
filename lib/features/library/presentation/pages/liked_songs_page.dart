import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/liked_tracks_header.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Liked songs (PRD S14): header actions, in-list search, sort, swipe-unlike.

/// Liked songs screen.
final class LikedSongsPage extends StatelessWidget {
  /// Creates the liked songs page.
  const LikedSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LikedTracksCubit>(
      create: (_) => getIt<LikedTracksCubit>()..load(),
      child: const _LikedSongsView(),
    );
  }
}

final class _LikedSongsView extends HookWidget {
  const _LikedSongsView();

  @override
  Widget build(BuildContext context) {
    final query = useTextEditingController();
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final cubit = context.read<LikedTracksCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Liked songs')),
      body: MaxContentWidth(
        child: BlocBuilder<LikedTracksCubit, LikedTracksState>(
          builder: (context, state) {
            switch (state.status) {
              case LikedTracksStatus.loading:
                return const StateView(
                  kind: StateKind.loading,
                  message: 'Loading…',
                );
              case LikedTracksStatus.error:
                return StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Could not load',
                  onRetry: cubit.load,
                );
              case LikedTracksStatus.empty:
                return const StateView(
                  kind: StateKind.empty,
                  message: 'Songs you like will appear here.',
                );
              case LikedTracksStatus.ready:
                break;
            }
            final tracks = state.visible;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, 8.w),
                  child: LikedTracksHeader(
                    count: state.tracks.length,
                    sort: state.sort,
                    onPlay: () => playFromCatalog(context, tracks, 0),
                    onShuffle: () => _shuffle(context, tracks),
                    onCycleSort: cubit.cycleSort,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: TextField(
                    controller: query,
                    onChanged: cubit.search,
                    decoration: const InputDecoration(
                      hintText: 'Search liked songs',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                SizedBox(height: 8.w),
                Expanded(
                  child: tracks.isEmpty
                      ? StateView(kind: StateKind.empty, message: 'No matches.')
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            pad,
                            8.w,
                            pad,
                            MediaQuery.paddingOf(context).bottom + 8.w,
                          ),
                          itemCount: tracks.length,
                          itemBuilder: (context, index) => _LikedRow(
                            track: tracks[index],
                            onPlay: () =>
                                playFromCatalog(context, tracks, index),
                            onUnlike: () => cubit.unlike(tracks[index].id),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _shuffle(BuildContext context, List<Track> tracks) {
    if (tracks.isEmpty) return;
    playFromCatalog(context, tracks, Random().nextInt(tracks.length));
  }
}

final class _LikedRow extends StatelessWidget {
  const _LikedRow({
    required this.track,
    required this.onPlay,
    required this.onUnlike,
  });

  final Track track;
  final VoidCallback onPlay;
  final VoidCallback onUnlike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Dismissible(
        key: ValueKey('liked-${track.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onUnlike(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            Icons.favorite_border,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        child: SongTile(
          title: track.title,
          subtitle: track.artist,
          artUrl: track.artUrl,
          track: track,
          onTap: onPlay,
        ),
      ),
    );
  }
}
