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
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Album detail screen (PRD S09).

/// Album page.
final class AlbumPage extends HookWidget {
  /// Creates the album page.
  const AlbumPage({
    super.key,
    required this.albumId,
    this.initialAlbum,
    this.heroTag,
  });

  /// Album id (raw JioSaavn id from the route).
  final String albumId;

  /// Metadata available from the tapped card before the details load.
  final Album? initialAlbum;

  /// Artwork tag from the card that opened this page.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<AlbumCubit>(), [albumId]);
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
              builder: (context, state) {
                final detail = state.detail;
                final metadata = detail?.album ?? initialAlbum;
                final status = switch (state.status) {
                  AlbumStatus.loading => const StateView(
                    kind: StateKind.loading,
                    message: 'Loading album?',
                  ),
                  AlbumStatus.error => StateView(
                    kind: StateKind.error,
                    message: state.error ?? 'Failed to load album',
                    onRetry: () => cubit.load(albumId),
                  ),
                  AlbumStatus.ready => null,
                };
                if (metadata == null && status != null) return status;
                return _Content(
                  album: metadata!,
                  heroTag: heroTag,
                  status: status,
                  songs: detail?.songs ?? const [],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _Content extends StatelessWidget {
  const _Content({
    required this.album,
    required this.heroTag,
    required this.status,
    required this.songs,
  });

  final Album album;
  final Object? heroTag;
  final Widget? status;
  final List<Track> songs;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: AlbumHeader(
            album: album,
            heroTag: heroTag,
            songCount: status == null ? songs.length : album.songCount,
            onPlayAll: songs.isEmpty
                ? null
                : () => playFromCatalog(context, songs, 0),
          ),
        ),
        if (status != null)
          SliverFillRemaining(hasScrollBody: false, child: status!)
        else ...[
          const SliverToBoxAdapter(child: SectionHeader(title: 'Songs')),
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
        ],
        // Leaves room for the system gesture inset.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.w),
        ),
      ],
    );
  }
}
