import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/aura_hero.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_episode.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';
import 'package:aura_music/features/podcast/presentation/bloc/podcast_cubit.dart';

/// Podcast show detail page with episode list and play actions.
final class PodcastPage extends HookWidget {
  /// Creates the podcast page.
  const PodcastPage({
    super.key,
    required this.showId,
    this.initialShow,
    this.heroTag,
  });

  /// Raw JioSaavn show id.
  final String showId;

  /// Optional preloaded show entity passed via route extra.
  final PodcastShow? initialShow;

  /// Artwork tag from the card that opened this page.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<PodcastCubit>(), [showId]);
    useEffect(() {
      cubit.load(showId, show: initialShow);
      return () => cubit.close();
    }, [cubit, showId]);

    final sizeClass = WindowSizeClass.of(context);

    return BlocProvider<PodcastCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            initialShow?.title ?? 'Podcast',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: MaxContentWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveInsets.side(sizeClass),
            ),
            child: BlocBuilder<PodcastCubit, PodcastState>(
              builder: (context, state) {
                final show = state.show ?? initialShow;
                final status = switch (state.status) {
                  PodcastStatus.loading => const StateView(
                    kind: StateKind.loading,
                    message: 'Loading podcast episodes…',
                  ),
                  PodcastStatus.error => StateView(
                    kind: StateKind.error,
                    message: state.error ?? 'Failed to load podcast episodes',
                    onRetry: () => cubit.load(showId, show: initialShow),
                  ),
                  PodcastStatus.ready => null,
                };
                if (show == null && status != null) return status;
                return _PodcastContent(
                  show: show,
                  episodes: state.episodes,
                  heroTag: heroTag,
                  status: status,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _PodcastContent extends StatelessWidget {
  const _PodcastContent({
    required this.show,
    required this.episodes,
    required this.heroTag,
    required this.status,
  });

  final PodcastShow? show;
  final List<PodcastEpisode> episodes;
  final Object? heroTag;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final playableTracks = episodes
        .map((e) => e.toTrack())
        .toList(growable: false);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        width: 120.w,
        height: 120.w,
        child: show?.artUrl != null && show!.artUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: show!.artUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 250,
                errorWidget: (_, _, _) => _fallbackCover(context),
              )
            : _fallbackCover(context),
      ),
    );

    final tag = heroTag;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Show Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show Cover Art
                tag == null ? cover : AuraHero(tag: tag, child: cover),
                SizedBox(width: 16.w),
                // Show Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      GlassSurface.fake(
                        borderRadius: 6.r,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.w,
                          ),
                          child: Text(
                            show?.badge?.isNotEmpty == true
                                ? show!.badge!
                                : 'PODCAST SHOW',
                            style: AppTypography.overline.copyWith(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.w),
                      // Title
                      Text(
                        show?.title ?? 'Podcast Show',
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (show?.subtitle?.isNotEmpty == true) ...[
                        SizedBox(height: 4.w),
                        Text(
                          show!.subtitle!,
                          style: AppTypography.body.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 6.w),
                      if (status == null)
                        Text(
                          '${episodes.length} episodes',
                          style: AppTypography.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (status != null)
          SliverFillRemaining(hasScrollBody: false, child: status!)
        else ...[
          // Action Buttons: Play All
          if (playableTracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.w),
                child: FilledButton.icon(
                  onPressed: () => playFromCatalog(context, playableTracks, 0),
                  icon: Icon(Icons.play_arrow_rounded, size: 24.r),
                  label: const Text('Play Latest Episode'),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(double.infinity, 44.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                  ),
                ),
              ),
            ),

          // Episodes Header
          const SliverToBoxAdapter(child: SectionHeader(title: 'All Episodes')),

          // Episodes List
          if (episodes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: const Center(
                  child: Text('No episodes available for this show.'),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final ep = episodes[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.w),
                  child: _EpisodeTile(
                    episode: ep,
                    index: index + 1,
                    onTap: () =>
                        playFromCatalog(context, playableTracks, index),
                  ),
                );
              },
            ),
        ],
        // Bottom padding for player bar
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24.w),
        ),
      ],
    );
  }

  Widget _fallbackCover(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.podcasts_rounded, size: 40.r)),
    );
  }
}

final class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.index,
    required this.onTap,
  });

  final PodcastEpisode episode;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDuration = _formatDuration(episode.duration);

    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
          child: Row(
            children: [
              // Episode Index or Art
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.art),
                child: SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: episode.artUrl != null && episode.artUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: episode.artUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          errorWidget: (_, _, _) => _indexAvatar(context),
                        )
                      : _indexAvatar(context),
                ),
              ),
              SizedBox(width: 12.w),
              // Episode Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3.w),
                    Row(
                      children: [
                        if (episode.releaseDate?.isNotEmpty == true) ...[
                          Text(
                            episode.releaseDate!,
                            style: AppTypography.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: AppTypography.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Text(
                          formattedDuration,
                          style: AppTypography.caption.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play Icon Button
              IconButton(
                onPressed: onTap,
                icon: Icon(Icons.play_circle_outline_rounded, size: 28.r),
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indexAvatar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          '$index',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'Podcast';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '$seconds sec';
  }
}
