import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Quick picks grid (PRD S03): sleek speed-dial tiles at the top of the feed.
///
/// A plain box (not a sliver) so the home feed can place it in one lazy
/// `SliverList`: the grid is tiny and bounded (`columns * 3` tiles), so a
/// shrink-wrapped grid costs one cheap layout pass.

/// Quick-picks grid.
final class HomeQuickPicks extends StatelessWidget {
  /// Creates the quick-picks grid.
  const HomeQuickPicks({
    super.key,
    required this.section,
    required this.padding,
    required this.columns,
    required this.onRetry,
  });

  /// Trending section (its first slice is the grid).
  final TrackSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Grid columns for the current window class.
  final int columns;

  /// Retry callback for the error state.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Same tile count for the skeleton and the data, so the grid keeps its
    // height when the songs land.
    final count = (columns * 3).clamp(4, 6);
    switch (section.status) {
      case SectionStatus.loading:
        return Shimmer(
          child: _grid(
            childCount: count,
            builder: (_, _) =>
                Skeleton(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      case SectionStatus.error:
        return StateView(
          kind: StateKind.error,
          message: section.error ?? 'Could not load music',
          onRetry: onRetry,
        );
      case SectionStatus.empty:
        return const StateView(
          kind: StateKind.empty,
          message: 'Nothing to play yet',
        );
      case SectionStatus.ready:
        final tracks = section.tracks;
        final quick = tracks.take(count).toList(growable: false);
        return _grid(
          childCount: quick.length,
          builder: (context, i) => _QuickPickTile(
            track: quick[i],
            onTap: () => playFromCatalog(context, tracks, i),
          ),
        );
    }
  }

  Widget _grid({
    required int childCount,
    required Widget Function(BuildContext, int) builder,
  }) => Padding(
    padding: EdgeInsets.symmetric(horizontal: padding, vertical: AppSpacing.xs),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8.w,
        crossAxisSpacing: 8.w,
        mainAxisExtent: 56.w,
      ),
      itemCount: childCount,
      itemBuilder: builder,
    ),
  );
}

final class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: 10.r,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                bottomLeft: Radius.circular(10.r),
              ),
              child: SizedBox(
                width: 56.w,
                height: 56.w,
                child: track.artUrl == null
                    ? ColoredBox(
                        color: AppColors.bgElevated,
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 20.r,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: track.artUrl!,
                        memCacheWidth: 140,
                        memCacheHeight: 140,
                        fit: BoxFit.cover,
                        fadeInDuration: AppDurations.fast,
                        errorWidget: (_, _, _) => ColoredBox(
                          color: AppColors.bgElevated,
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 20.r,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.w),
                    Text(
                      track.artist,
                      style: AppTypography.caption.copyWith(fontSize: 11.sp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
