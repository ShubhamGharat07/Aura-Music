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
import 'package:aura_music/features/album/presentation/bloc/album_cubit.dart';
import 'package:aura_music/features/album/presentation/widgets/album_header.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';

/// Album detail screen (PRD S09).

/// Album page.
final class AlbumPage extends HookWidget {
  /// Creates the album page.
  const AlbumPage({super.key, required this.albumId});

  /// Album id (raw JioSaavn id from the route).
  final String albumId;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<AlbumCubit>(), const []);
    useEffect(() {
      cubit.load(albumId);
      return () => cubit.close();
    }, [cubit, albumId]);
    final sizeClass = WindowSizeClass.of(context);
    return BlocProvider<AlbumCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(),
        body: MaxContentWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveInsets.side(sizeClass),
            ),
            child: BlocBuilder<AlbumCubit, AlbumState>(
              builder: (context, state) => switch (state.status) {
                AlbumStatus.loading => const StateView(
                  kind: StateKind.loading,
                  message: 'Loading album…',
                ),
                AlbumStatus.error => StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Failed to load album',
                  onRetry: () => cubit.load(albumId),
                ),
                AlbumStatus.ready => _Ready(detail: state.detail!),
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

  final AlbumDetail detail;

  @override
  Widget build(BuildContext context) {
    final songs = detail.songs;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AlbumHeader(
            album: detail.album,
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
