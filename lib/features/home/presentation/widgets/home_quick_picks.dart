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
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// The top-picks opener for Home.
///
/// A horizontal rail of two-row columns: the first viewport shows the same
/// six covers as before, the next column peeks in from the right edge, and
/// scrolling reveals the rest with a soft fade-in per column.
final class HomeQuickPicks extends StatelessWidget {
  /// Creates the top-picks rail.
  const HomeQuickPicks({
    super.key,
    required this.section,
    required this.padding,
    required this.columns,
    required this.onRetry,
  });

  /// Trending section (its first tracks are the picks).
  final TrackSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Fully visible rail columns for the current window class.
  final int columns;

  /// Retry callback for the error state.
  final VoidCallback onRetry;

  /// Two viewports of six: 3 columns x 2 rows per "page".
  static const int _limit = 12;

  @override
  Widget build(BuildContext context) {
    if (section.status == SectionStatus.empty) return const SizedBox.shrink();

    final tracks = section.tracks.take(_limit).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.xl,
            padding,
            AppSpacing.md,
          ),
          child: SectionHeader(
            title: 'Top picks',
            onSeeAll: section.status == SectionStatus.ready
                ? () {
                    HapticFeedback.selectionClick();
                    context.push(AppRoutes.topPicks);
                  }
                : null,
          ),
        ),
        switch (section.status) {
          SectionStatus.loading => Shimmer(
            child: _PicksPager(
              tracks: const [],
              columns: columns,
              padding: padding,
            ),
          ),
          SectionStatus.error => StateView(
            kind: StateKind.error,
            message: section.error ?? 'Could not load music',
            onRetry: onRetry,
          ),
          _ => _PicksPager(tracks: tracks, columns: columns, padding: padding),
        },
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// A paged grid of covers: the home screen opens on the first page of
/// [columns] x 2 rows and swiping reveals the next page of picks.
///
/// Every tile has a fixed two-line text block, and rows/columns are separated
/// by real gaps so the artwork never looks cramped.
final class _PicksPager extends StatelessWidget {
  const _PicksPager({
    required this.tracks,
    required this.columns,
    required this.padding,
  });

  final List<Track> tracks;
  final int columns;
  final double padding;

  static const double _gap = 12.0;
  static const double _rowGap = 18.0;

  /// Reserved text space per tile: two lines of the 14.5sp/1.2 title and two
  /// lines of the 12sp/1.35 artist line, plus a little slack so descenders
  /// are never clipped at the bottom of the block. Keep in sync with
  /// [_TopPickTile].
  static const double _titleBlock = 34.8 + 9;
  static const double _artistBlock = 32.4 + 9;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final titleBlock = scaler.scale(_titleBlock.sp);
    final artistBlock = scaler.scale(_artistBlock.sp);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = columns.clamp(2, 6);
        final rows = cols >= 6 ? 1 : 2;
        final perPage = cols * rows;
        final cell =
            (constraints.maxWidth - 2 * padding - _gap.w * (cols - 1)) / cols;
        final tileHeight = cell + 9.h + titleBlock + 3.h + artistBlock;
        final pageCount = tracks.isEmpty ? 1 : (tracks.length / perPage).ceil();
        return SizedBox(
          height: tileHeight * rows + _rowGap.h * (rows - 1) + 4,
          child: PageView.builder(
            allowImplicitScrolling: true,
            itemCount: pageCount,
            itemBuilder: (context, page) => _PicksPage(
              page: page,
              perPage: perPage,
              cols: cols,
              rows: rows,
              cell: cell,
              titleBlock: titleBlock,
              artistBlock: artistBlock,
              loading: tracks.isEmpty,
              tracks: tracks,
              padding: padding,
              onTap: tracks.isEmpty
                  ? null
                  : (trackIndex) {
                      HapticFeedback.lightImpact();
                      playFromCatalog(context, tracks, trackIndex);
                    },
            ),
          ),
        );
      },
    );
  }
}

/// One page of [cols] x [rows] covers, fading in when the page is built.
final class _PicksPage extends HookWidget {
  const _PicksPage({
    required this.page,
    required this.perPage,
    required this.cols,
    required this.rows,
    required this.cell,
    required this.titleBlock,
    required this.artistBlock,
    required this.loading,
    required this.tracks,
    required this.padding,
    required this.onTap,
  });

  final int page;
  final int perPage;
  final int cols;
  final int rows;
  final double cell;
  final double titleBlock;
  final double artistBlock;
  final bool loading;
  final List<Track> tracks;
  final double padding;
  final void Function(int trackIndex)? onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 320),
    );
    useEffect(() {
      if (reduceMotion) {
        controller.value = 1;
      } else {
        controller.forward();
      }
      return null;
    }, [controller, reduceMotion]);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) SizedBox(height: _PicksPager._rowGap.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < cols; col++) ...[
                  if (col > 0) SizedBox(width: _PicksPager._gap.w),
                  Expanded(child: _staggered(row * cols + col, controller)),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tiles settle in one after another. The fade starts near full opacity so
  /// a freshly mounted page never reads as a black gap while scrolling.
  Widget _staggered(int slot, AnimationController controller) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval((slot * 0.05).clamp(0.0, 0.25), 1, curve: AppCurves.out),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.9, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: _tile(slot),
      ),
    );
  }

  Widget _tile(int slot) {
    if (loading) {
      return _PickSkeleton(
        cell: cell,
        titleBlock: titleBlock,
        artistBlock: artistBlock,
      );
    }
    final trackIndex = page * perPage + slot;
    if (trackIndex >= tracks.length) return const SizedBox.shrink();
    return _TopPickTile(
      track: tracks[trackIndex],
      index: trackIndex,
      cell: cell,
      titleBlock: titleBlock,
      artistBlock: artistBlock,
      onTap: onTap == null ? null : () => onTap!(trackIndex),
    );
  }
}

final class _PickSkeleton extends StatelessWidget {
  const _PickSkeleton({
    required this.cell,
    required this.titleBlock,
    required this.artistBlock,
  });

  final double cell;
  final double titleBlock;
  final double artistBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Skeleton(borderRadius: BorderRadius.circular(AppRadius.card)),
        ),
        SizedBox(height: 9.h),
        SizedBox(
          height: titleBlock,
          child: Align(
            alignment: Alignment.topLeft,
            child: Skeleton(
              width: cell * 0.78,
              height: 9.h,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        SizedBox(
          height: artistBlock,
          child: Align(
            alignment: Alignment.topLeft,
            child: Skeleton(
              width: cell * 0.48,
              height: 7.h,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

final class _TopPickTile extends HookWidget {
  const _TopPickTile({
    required this.track,
    required this.index,
    required this.cell,
    required this.titleBlock,
    required this.artistBlock,
    required this.onTap,
  });

  final Track track;
  final int index;
  final double cell;
  final double titleBlock;
  final double artistBlock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.975 : 1,
      duration: AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => pressed.value = value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _art(),
                ),
              ),
              SizedBox(height: 9.h),
              SizedBox(
                height: titleBlock,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    track.title,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 14.5.sp,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              SizedBox(
                height: artistBlock,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    track.artist,
                    style: AppTypography.caption.copyWith(fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _art() {
    final fallback = const ColoredBox(
      color: AppColors.bgElevated,
      child: Icon(
        Icons.music_note_rounded,
        size: 22,
        color: AppColors.textTertiary,
      ),
    );
    final url = track.artUrl;
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: 300,
      memCacheHeight: 300,
      fit: BoxFit.cover,
      fadeInDuration: AppDurations.fast,
      placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
