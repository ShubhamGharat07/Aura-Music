import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/media_card.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/catalog/presentation/album_labels.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';

/// Responsive album grid section for the home feed (PRD S03).
///
/// Only [maxRows] rows are drawn inline and the rest live behind "See all", so
/// a browse grid cannot swallow the whole feed. Empty sections collapse. The
/// section is a box (not a sliver) so the feed can host it in one lazy
/// `SliverList`, and its skeleton uses the same grid so nothing jumps when the
/// data lands.

/// One home album grid.
final class HomeAlbumGrid extends StatelessWidget {
  /// Creates an album grid section.
  const HomeAlbumGrid({
    super.key,
    required this.title,
    required this.section,
    required this.padding,
    this.maxRows = 2,
    this.onSeeAll,
    this.onRetry,
  });

  /// Section title.
  final String title;

  /// Section data.
  final AlbumSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Rows drawn inline before "See all".
  final int maxRows;

  /// "See all" callback (null hides it).
  final VoidCallback? onSeeAll;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  static const double _cardWidth = 150;

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
          child: SectionHeader(
            title: title,
            onSeeAll: section.status == SectionStatus.ready ? onSeeAll : null,
          ),
        ),
        switch (section.status) {
          SectionStatus.loading => Shimmer(
            child: _grid(context, skeleton: true),
          ),
          SectionStatus.error => _error(),
          _ => _grid(context, skeleton: false),
        },
      ],
    );
  }

  /// Draws the same grid for both the skeleton and the data, so the section
  /// keeps its height while it loads.
  Widget _grid(BuildContext context, {required bool skeleton}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: padding),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final delegate = AdaptiveGrid.delegate(
          availableWidth: constraints.maxWidth,
          targetCardWidth: _cardWidth,
        );
        final albums = section.albums
            .take(delegate.crossAxisCount * maxRows)
            .toList(growable: false);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: delegate,
          itemCount: skeleton
              ? delegate.crossAxisCount * maxRows
              : albums.length,
          itemBuilder: (context, i) => skeleton
              ? Skeleton(borderRadius: BorderRadius.circular(AppRadius.art))
              : MediaCard(
                  title: albums[i].title,
                  subtitle: albums[i].cardSubtitle,
                  artUrl: albums[i].artUrl,
                  onTap: () =>
                      context.push('${AppRoutes.album}/${albums[i].id}'),
                ),
        );
      },
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
}
