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
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Artist detail screen (PRD S10): top songs + albums.

/// Artist page.
final class ArtistPage extends HookWidget {
  /// Creates the artist page.
  const ArtistPage({
    super.key,
    required this.artistId,
    this.initialArtist,
    this.heroTag,
  });

  /// Artist id (raw JioSaavn id from the route).
  final String artistId;

  /// Metadata available from the tapped card before the details load.
  final Artist? initialArtist;

  /// Artwork tag from the card that opened this page.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<ArtistCubit>(), [artistId]);
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
              builder: (context, state) {
                final detail = state.detail;
                final metadata = detail?.artist ?? initialArtist;
                final status = switch (state.status) {
                  ArtistStatus.loading => const StateView(
                    kind: StateKind.loading,
                    message: 'Loading artist?',
                  ),
                  ArtistStatus.error => StateView(
                    kind: StateKind.error,
                    message: state.error ?? 'Failed to load artist',
                    onRetry: () => cubit.load(artistId),
                  ),
                  ArtistStatus.ready => null,
                };
                if (metadata == null && status != null) return status;
                return _Content(
                  artist: metadata!,
                  heroTag: heroTag,
                  status: status,
                  songs: detail?.topSongs ?? const [],
                  albums: detail?.albums ?? const [],
                  followerCount: detail?.followerCount,
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
    required this.artist,
    required this.heroTag,
    required this.status,
    required this.songs,
    this.followerCount,
    required this.albums,
  });

  final Artist artist;
  final Object? heroTag;
  final Widget? status;
  final List<Track> songs;
  final List<Album> albums;
  final int? followerCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ArtistHeader(
              artist: artist,
              heroTag: heroTag,
              followerCount: followerCount,
              onPlay: songs.isEmpty
                  ? null
                  : () => playFromCatalog(context, songs, 0),
            ),
          ),
          if (status != null)
            SliverFillRemaining(hasScrollBody: false, child: status!),
          if (status == null && songs.isNotEmpty) ...<Widget>[
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
          if (status == null && albums.isNotEmpty) ...<Widget>[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Albums')),
            SliverGrid(
              gridDelegate: AdaptiveGrid.delegate(
                availableWidth: constraints.maxWidth,
                targetCardWidth: 150,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final item = albums[i];
                final tag = ('artist-albums', item.id, i);
                return MediaCard(
                  heroTag: tag,
                  title: item.title,
                  subtitle: item.artist,
                  artUrl: item.artUrl,
                  onTap: () => context.push(
                    '${AppRoutes.album}/${item.id}',
                    extra: (item, tag),
                  ),
                );
              }, childCount: albums.length),
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
