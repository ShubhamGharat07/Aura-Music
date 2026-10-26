import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/playlist/presentation/bloc/playlist_cubit.dart';
import 'package:aura_music/features/playlist/presentation/widgets/playlist_header.dart';

/// Playlist detail screen (PRD S11).

/// Playlist page.
final class PlaylistPage extends HookWidget {
  /// Creates the playlist page.
  const PlaylistPage({super.key, required this.playlistId});

  /// Playlist id (raw JioSaavn id from the route).
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<PlaylistCubit>(), const []);
    useEffect(() {
      cubit.load(playlistId);
      return () => cubit.close();
    }, [cubit, playlistId]);
    final sizeClass = WindowSizeClass.of(context);
    return BlocProvider<PlaylistCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(),
        body: MaxContentWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveInsets.side(sizeClass),
            ),
            child: BlocBuilder<PlaylistCubit, PlaylistState>(
              builder: (context, state) => switch (state.status) {
                PlaylistStatus.loading => const StateView(
                  kind: StateKind.loading,
                  message: 'Loading playlist…',
                ),
                PlaylistStatus.error => StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Failed to load playlist',
                  onRetry: () => cubit.load(playlistId),
                ),
                PlaylistStatus.ready => _Ready(detail: state.detail!),
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _Ready extends StatelessWidget {
  const _Ready({required this.detail});

  final PlaylistDetail detail;

  @override
  Widget build(BuildContext context) {
    final songs = detail.songs;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PlaylistHeader(
            playlist: detail.playlist,
            songCount: songs.length,
            onPlayAll: songs.isEmpty
                ? null
                : () => playFromCatalog(context, songs, 0),
          ),
        ),
        SliverToBoxAdapter(child: SectionHeader(title: 'Songs')),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: SongTile(
              title: songs[i].title,
              subtitle: songs[i].subtitle,
              artUrl: songs[i].artUrl,
              track: songs[i],
              onTap: () => playFromCatalog(context, songs, i),
            ),
          ),
        ),
        // Leaves room for the system gesture inset.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.w),
        ),
      ],
    );
  }
}
