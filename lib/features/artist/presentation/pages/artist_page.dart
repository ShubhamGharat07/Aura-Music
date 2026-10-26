import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/ui/media_card.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/artist/presentation/bloc/artist_cubit.dart';
import 'package:aura_music/features/artist/presentation/widgets/artist_header.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';

/// Artist detail screen (PRD S10): top songs + albums.

/// Artist page.
final class ArtistPage extends HookWidget {
  /// Creates the artist page.
  const ArtistPage({super.key, required this.artistId});

  /// Artist id (raw JioSaavn id from the route).
  final String artistId;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<ArtistCubit>(), const []);
    useEffect(() {
      cubit.load(artistId);
      return () => cubit.close();
    }, [cubit, artistId]);
    final sizeClass = WindowSizeClass.of(context);
    return BlocProvider<ArtistCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(),
        body: MaxContentWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveInsets.side(sizeClass),
            ),
            child: BlocBuilder<ArtistCubit, ArtistState>(
              builder: (context, state) => switch (state.status) {
                ArtistStatus.loading => const StateView(
                  kind: StateKind.loading,
                  message: 'Loading artist…',
                ),
                ArtistStatus.error => StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Failed to load artist',
                  onRetry: () => cubit.load(artistId),
                ),
                ArtistStatus.ready => _Ready(detail: state.detail!),
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

  final ArtistDetail detail;

  @override
  Widget build(BuildContext context) {
    final songs = detail.topSongs;
    final albums = detail.albums;
    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ArtistHeader(
              artist: detail.artist,
              followerCount: detail.followerCount,
              onPlay: songs.isEmpty
                  ? null
                  : () => playFromCatalog(context, songs, 0),
            ),
          ),
          if (songs.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(child: SectionHeader(title: 'Top songs')),
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
          if (albums.isNotEmpty) ...<Widget>[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Albums')),
            SliverGrid(
              gridDelegate: AdaptiveGrid.delegate(
                availableWidth: constraints.maxWidth,
                targetCardWidth: 150,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => MediaCard(
                  title: albums[i].title,
                  subtitle: albums[i].artist,
                  artUrl: albums[i].artUrl,
                  onTap: () =>
                      context.push('${AppRoutes.album}/${albums[i].id}'),
                ),
                childCount: albums.length,
              ),
            ),
          ],
          // Leaves room for the system gesture inset.
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 8.w),
          ),
        ],
      ),
    );
  }
}
