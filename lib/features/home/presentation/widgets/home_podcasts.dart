import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/aura_hero.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/podcast/domain/entities/podcast_show.dart';

/// Horizontal carousel displaying top podcast shows on the Home feed.
final class HomePodcasts extends StatelessWidget {
  /// Creates the podcast section.
  const HomePodcasts({
    super.key,
    required this.section,
    required this.padding,
    this.cardWidth = 156,
    this.onRetry,
  });

  final PodcastSection section;
  final double padding;
  final double cardWidth;
  final VoidCallback? onRetry;

  static const double _carouselHeight = 226;

  @override
  Widget build(BuildContext context) {
    if (section.status == SectionStatus.empty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.lg,
            padding,
            AppSpacing.xs,
          ),
          child: const SectionHeader(title: 'Top Podcasts & Shows'),
        ),
        SizedBox(
          height: _carouselHeight.w,
          child: switch (section.status) {
            SectionStatus.loading => _buildSkeleton(context),
            SectionStatus.error => _buildError(context),
            SectionStatus.ready || SectionStatus.empty => _buildList(context),
          },
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final shows = section.shows;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: padding),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: shows.length,
      separatorBuilder: (_, _) => SizedBox(width: 12.w),
      itemBuilder: (context, index) {
        final show = shows[index];
        final tag = ('home-podcast', show.id, index);
        return _PodcastCard(
          heroTag: tag,
          show: show,
          cardWidth: cardWidth.w,
          onTap: () => context.push(
            '${AppRoutes.podcast}/${show.id}',
            extra: (show, tag),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: padding),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, _) => SizedBox(
          width: cardWidth.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(
                width: cardWidth.w,
                height: cardWidth.w,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              SizedBox(height: 8.w),
              Skeleton(
                width: cardWidth.w * 0.8,
                height: 14.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
              SizedBox(height: 4.w),
              Skeleton(
                width: cardWidth.w * 0.5,
                height: 12.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.podcasts_outlined, size: 20.r),
            SizedBox(width: 8.w),
            Text('Failed to load podcasts', style: AppTypography.caption),
            if (onRetry != null) ...[
              SizedBox(width: 8.w),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PodcastCard extends StatelessWidget {
  const _PodcastCard({
    required this.show,
    required this.cardWidth,
    required this.onTap,
    required this.heroTag,
  });

  final PodcastShow show;
  final double cardWidth;
  final VoidCallback onTap;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Artwork container with badge
            Stack(
              children: [
                AuraHero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: show.artUrl != null && show.artUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: show.artUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 250,
                              errorWidget: (_, _, _) => _fallbackArt(context),
                            )
                          : _fallbackArt(context),
                    ),
                  ),
                ),
                // Podcast badge pill
                Positioned(
                  top: 8.w,
                  left: 8.w,
                  child: GlassSurface.fake(
                    borderRadius: 6.r,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.w,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_none_rounded,
                            size: 11.w,
                            color: accent,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            show.badge?.isNotEmpty == true
                                ? show.badge!
                                : 'SHOW',
                            style: AppTypography.overline.copyWith(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.w),
            // Title
            Text(
              show.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.w),
            // Subtitle
            Text(
              show.subtitle?.isNotEmpty == true ? show.subtitle! : 'Podcast',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackArt(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.podcasts_rounded, size: 36.r)),
    );
  }
}
