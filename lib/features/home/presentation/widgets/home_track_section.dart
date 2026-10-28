import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/media_card.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';

/// Horizontal track carousel with optional arrow buttons (PRD S03).
/// Empty sections collapse to nothing so the feed stays tidy.

/// One home carousel section.
final class HomeTrackSection extends HookWidget {
  /// Creates a carousel section.
  const HomeTrackSection({
    super.key,
    required this.title,
    required this.section,
    required this.padding,
    required this.cardWidth,
    required this.height,
    this.onSeeAll,
    this.onRetry,
    this.showArrows = false,
  });

  /// Section title.
  final String title;

  /// Section data.
  final TrackSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Card width (140 compact / 160 medium+).
  final double cardWidth;

  /// Carousel height.
  final double height;

  /// "See all" callback (null hides it).
  final VoidCallback? onSeeAll;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  /// Show arrow buttons (Expanded / Large).
  final bool showArrows;

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    if (section.status == SectionStatus.empty) return const SizedBox.shrink();
    final dense = MediaQuery.sizeOf(context).height < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            dense ? AppSpacing.sm : AppSpacing.xl,
            padding,
            AppSpacing.xs,
          ),
          child: SectionHeader(
            title: title,
            onSeeAll: section.status == SectionStatus.ready ? onSeeAll : null,
          ),
        ),
        switch (section.status) {
          SectionStatus.loading => _loading(),
          SectionStatus.error => _error(),
          _ => _carousel(context, controller),
        },
      ],
    );
  }

  /// Skeleton cards laid out exactly like the real row, so the section keeps
  /// its height and the swap to real art is a smooth shimmer-to-content fade.
  Widget _loading() => Shimmer(
    child: SizedBox(
      height: height,
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
              AspectRatio(aspectRatio: 1, child: Skeleton()),
              SizedBox(height: AppSpacing.sm),
              Skeleton(height: 13.w, width: cardWidth * 0.72),
              SizedBox(height: 5.w),
              Skeleton(height: 11.w, width: cardWidth * 0.5),
            ],
          ),
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
            section.error ?? 'Could not load',
            style: AppTypography.caption,
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );

  Widget _carousel(BuildContext context, ScrollController controller) {
    final tracks = section.tracks;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: tracks.length,
            separatorBuilder: (_, _) => SizedBox(width: 14.w),
            itemBuilder: (_, i) => SizedBox(
              width: cardWidth,
              child: MediaCard(
                title: tracks[i].title,
                subtitle: tracks[i].artist,
                artUrl: tracks[i].artUrl,
                onTap: () => playFromCatalog(context, tracks, i),
              ),
            ),
          ),
          if (showArrows) ...[
            _arrow(
              Alignment.centerLeft,
              Icons.chevron_left,
              () => _scroll(controller, -1),
            ),
            _arrow(
              Alignment.centerRight,
              Icons.chevron_right,
              () => _scroll(controller, 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(Alignment alignment, IconData icon, VoidCallback onTap) =>
      Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: IconButton.filledTonal(
            onPressed: onTap,
            icon: Icon(icon),
            tooltip: 'Scroll',
          ),
        ),
      );

  void _scroll(ScrollController controller, double direction) {
    if (!controller.hasClients) return;
    final max = controller.position.maxScrollExtent;
    final target = (controller.offset + direction * 240).clamp(0.0, max);
    controller.animateTo(
      target,
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
    );
  }
}
