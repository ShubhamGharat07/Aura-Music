import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_trending.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/home/presentation/widgets/top_pick_tile.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// The top-picks opener for Home.
///
/// A swipeable grid with six tracks per page across compact and wide layouts.
final class HomeQuickPicks extends StatefulWidget {
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

  @override
  State<HomeQuickPicks> createState() => _HomeQuickPicksState();
}

final class _HomeQuickPicksState extends State<HomeQuickPicks>
    with AutomaticKeepAliveClientMixin<HomeQuickPicks> {
  // Retain the ready pager and its decoded artwork when the feed scrolls away.
  @override
  bool get wantKeepAlive => widget.section.status == SectionStatus.ready;

  @override
  void didUpdateWidget(HomeQuickPicks oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final HomeQuickPicks(:section, :padding, :columns, :onRetry) = widget;
    if (section.status == SectionStatus.empty) return const SizedBox.shrink();

    final tracks = section.tracks
        .take(GetHomeTrending.homePickLimit)
        .toList(growable: false);
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
final class _PicksPager extends HookWidget {
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
  /// [TopPickTile].
  static const double _titleBlock = 34.8 + 9;
  static const double _artistBlock = 32.4 + 9;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final direction = Directionality.of(context) == TextDirection.ltr
        ? 1.0
        : -1.0;
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
            key: PageStorageKey(
              tracks.isEmpty ? 'top-picks-loading' : 'top-picks',
            ),
            controller: controller,
            allowImplicitScrolling: true,
            itemCount: pageCount,
            itemBuilder: (context, page) {
              final grid = _PicksPage(
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
              );
              if (reduceMotion || pageCount == 1) return grid;
              return AnimatedBuilder(
                animation: controller,
                child: grid,
                builder: (context, child) {
                  final current = controller.hasClients
                      ? controller.page
                      : null;
                  final delta = ((current ?? page.toDouble()) - page).clamp(
                    -1.0,
                    1.0,
                  );
                  // A slight drift adds depth during the swipe. Both effects
                  // follow the finger and land at identity on the snapped page.
                  final scale = 1 - 0.018 * delta * delta;
                  return Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..translateByDouble(direction * delta * 8, 0, 0, 1)
                      ..scaleByDouble(scale, scale, 1, 1),
                    child: child,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// One grid page, built lazily by the pager.
final class _PicksPage extends StatelessWidget {
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
                  Expanded(child: _tile(row * cols + col)),
                ],
              ],
            ),
          ],
        ],
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
    return TopPickTile(
      track: tracks[trackIndex],
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
              borderRadius: BorderRadius.circular(3.r),
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
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ),
      ],
    );
  }
}
