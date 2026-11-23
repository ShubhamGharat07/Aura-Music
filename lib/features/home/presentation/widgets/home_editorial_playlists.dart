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

/// "Editor's Picks" carousel (PRD S03): the catalog's hand-curated playlists.
///
/// Deliberately quieter than the charts row — cover, one title line, one
/// subtitle — so the two sections read as different editorial weights.
final class HomeEditorialPlaylists extends StatelessWidget {
  /// Creates the editor's picks section.
  const HomeEditorialPlaylists({
    super.key,
    required this.section,
    required this.padding,
    this.cardWidth = 156,
    this.onRetry,
  });

  /// Section data.
  final PlaylistSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Card width.
  final double cardWidth;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  double get _rowHeight => cardWidth + 54;

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
          child: const SectionHeader(title: "Editor's Picks"),
        ),
        SizedBox(
          height: _rowHeight,
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
    itemBuilder: (_, i) => _PlaylistCard(
      playlist: section.playlists[i],
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
      itemBuilder: (_, _) => SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(
              width: cardWidth,
              height: cardWidth,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            SizedBox(height: 8.w),
            Skeleton(
              width: cardWidth * 0.76,
              height: 13.w,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 5.w),
            Skeleton(
              width: cardWidth * 0.46,
              height: 11.w,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _error() => Padding(
    padding: EdgeInsets.fromLTRB(padding, 4.w, padding, 4.w),
    child: Row(
      children: [
        Expanded(
          child: Text(
            section.error ?? 'Could not load playlists',
            style: AppTypography.caption,
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

final class _PlaylistCard extends HookWidget {
  const _PlaylistCard({required this.playlist, required this.width});

  final Playlist playlist;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      width: width,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(borderRadius: radius, child: _art()),
                ),
                SizedBox(height: 8.w),
                Text(
                  playlist.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  _subtitle(playlist),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _art() {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          size: 28.r,
          color: AppColors.textTertiary,
        ),
      ),
    );
    final url = playlist.artUrl;
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 400,
      fadeInDuration: AppDurations.fast,
      fadeInCurve: AppCurves.out,
      placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

String _subtitle(Playlist playlist) {
  final subtitle = playlist.subtitle?.trim();
  if (subtitle != null && subtitle.isNotEmpty) return subtitle;
  final count = playlist.songCount;
  if (count == null || count <= 0) return 'Playlist';
  return count == 1 ? '1 song' : '$count songs';
}
