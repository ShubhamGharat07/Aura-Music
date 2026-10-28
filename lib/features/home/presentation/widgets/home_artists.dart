import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';

/// Popular-artist row for the home feed (PRD S03): circular portraits with the
/// artist name underneath, scrolling horizontally like the other carousels.
///
/// The row is a lazy horizontal list of fixed-size bubbles, so a long artist
/// list costs the same as a short one and never janks the feed scroll.

/// Popular artists row.
final class HomeArtists extends StatelessWidget {
  /// Creates the artists row.
  const HomeArtists({
    super.key,
    required this.section,
    required this.padding,
    this.onRetry,
  });

  /// Section data.
  final ArtistSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  /// Bubble diameter.
  static const double _avatar = 84;

  /// Bubble width (portrait + name).
  static const double _bubble = 92;

  /// Row height, fixed so the feed never shifts while the row loads.
  static const double _rowHeight = 136;

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
          child: const SectionHeader(title: 'Popular artists'),
        ),
        SizedBox(height: _rowHeight, child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) => switch (section.status) {
    SectionStatus.loading => _loading(),
    SectionStatus.error => _error(),
    _ => _row(context),
  };

  /// Skeleton bubbles in the real row's geometry, so the row keeps its height
  /// and swaps over smoothly once the portraits arrive.
  Widget _loading() => Shimmer(
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: 5,
      separatorBuilder: (_, _) => SizedBox(width: 14.w),
      itemBuilder: (_, _) => SizedBox(
        width: _bubble,
        child: Column(
          children: [
            Skeleton(
              width: _avatar,
              height: _avatar,
              borderRadius: BorderRadius.circular(_avatar / 2),
            ),
            SizedBox(height: 8.w),
            Skeleton(width: 70.w, height: 12.w),
          ],
        ),
      ),
    ),
  );

  Widget _row(BuildContext context) => ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: padding),
    itemCount: section.artists.length,
    separatorBuilder: (_, _) => SizedBox(width: 14.w),
    itemBuilder: (_, i) =>
        _ArtistBubble(artist: section.artists[i], size: _bubble),
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

final class _ArtistBubble extends StatelessWidget {
  const _ArtistBubble({required this.artist, required this.size});

  final Artist artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: InkWell(
        onTap: () => context.push('${AppRoutes.artist}/${artist.id}'),
        borderRadius: BorderRadius.circular(size / 2),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: HomeArtists._avatar,
                height: HomeArtists._avatar,
                child: _portrait(),
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              artist.name,
              style: AppTypography.caption,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _portrait() {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Icon(
        Icons.person_outline,
        color: AppColors.textTertiary,
        size: 32.r,
      ),
    );
    final url = artist.imageUrl;
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 200,
      fadeInDuration: AppDurations.fast,
      placeholder: (context, _) =>
          const ColoredBox(color: AppColors.bgElevated),
      errorWidget: (context, _, _) => fallback,
    );
  }
}
