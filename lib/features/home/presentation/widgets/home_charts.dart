import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';

/// "Top Charts" carousel (PRD S03): the catalog's editorial chart playlists.
///
/// Each card is a cover with the chart rank stamped on it and the title set
/// over a bottom scrim, so the row reads as a chart rather than another album
/// grid. Tapping opens the playlist.
final class HomeCharts extends StatelessWidget {
  /// Creates the charts section.
  const HomeCharts({
    super.key,
    required this.section,
    required this.padding,
    this.cardWidth = 164,
    this.onRetry,
  });

  /// Section data.
  final PlaylistSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Card width (also its height: the cover is square).
  final double cardWidth;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (section.status == SectionStatus.empty) return const SizedBox.shrink();
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
          child: const SectionHeader(title: 'Top Charts'),
        ),
        SizedBox(
          height: cardWidth,
          child: switch (section.status) {
            SectionStatus.loading => _loading(),
            SectionStatus.error => _error(),
            _ => _list(),
          },
        ),
      ],
    );
  }

  Widget _list() => ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: padding),
    physics: const BouncingScrollPhysics(),
    itemCount: section.playlists.length,
    separatorBuilder: (_, _) => SizedBox(width: 14.w),
    itemBuilder: (_, i) => _ChartCard(
      playlist: section.playlists[i],
      rank: i + 1,
      width: cardWidth,
    ),
  );

  Widget _loading() => Shimmer(
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(width: 14.w),
      itemBuilder: (_, _) => Skeleton(
        width: cardWidth,
        height: cardWidth,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  );

  Widget _error() => Padding(
    padding: EdgeInsets.fromLTRB(padding, 4.w, padding, 4.w),
    child: Row(
      children: [
        Expanded(
          child: Text(
            section.error ?? 'Could not load charts',
            style: AppTypography.caption,
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

final class _ChartCard extends HookWidget {
  const _ChartCard({
    required this.playlist,
    required this.rank,
    required this.width,
  });

  final Playlist playlist;
  final int rank;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      width: width,
      height: width,
      child: AnimatedScale(
        scale: pressed.value && !reduceMotion ? 0.975 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.out,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('${AppRoutes.playlist}/${playlist.id}');
            },
            onHighlightChanged: (value) => pressed.value = value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _art(radius),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.34, 1],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(top: 9.w, left: 9.w, child: _rankBadge()),
                Positioned(
                  left: 11.w,
                  right: 11.w,
                  bottom: 10.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playlist.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 14.sp,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.w),
                      Text(
                        _countLabel(playlist),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankBadge() => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.w),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.44),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.18),
        width: 0.6,
      ),
    ),
    child: Text(
      '#$rank',
      style: AppTypography.overline.copyWith(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.white,
      ),
    ),
  );

  Widget _art(BorderRadius radius) {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Center(
        child: Icon(
          Icons.bar_chart_rounded,
          size: 30.r,
          color: AppColors.textTertiary,
        ),
      ),
    );
    final url = playlist.artUrl;
    if (url == null) {
      return ClipRRect(borderRadius: radius, child: fallback);
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 400,
        memCacheHeight: 400,
        fadeInDuration: AppDurations.fast,
        fadeInCurve: AppCurves.out,
        placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

String _countLabel(Playlist playlist) {
  final count = playlist.songCount;
  if (count == null || count <= 0) return 'Playlist';
  return count == 1 ? '1 song' : '$count songs';
}
