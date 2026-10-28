import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Collection card for the library grid (PRD S12).
///
/// Artwork, title, count. No outer glass card around an inner rounded image:
/// nested corners and double padding were making every playlist look like a
/// widget demo.

/// Grid card: cover + title + subtitle.
final class CollectionCard extends StatelessWidget {
  /// Creates a collection card.
  const CollectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.artUrl,
    required this.onTap,
  });

  /// Collection name.
  final String title;

  /// Secondary line (artist or track count).
  final String subtitle;

  /// Cover art URL (null = placeholder).
  final String? artUrl;

  /// Tap action.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.art);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: AppColors.bgElevated,
                  border: Border.all(color: AppColors.glassBorder, width: 0.6),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: artUrl == null
                      ? ColoredBox(
                          color: AppColors.bgElevated,
                          child: Icon(
                            Icons.album_outlined,
                            size: 32.r,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: artUrl!,
                          memCacheWidth: 400,
                          memCacheHeight: 400,
                          fit: BoxFit.cover,
                          fadeInDuration: AppDurations.fast,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: AppColors.bgElevated,
                            child: Icon(
                              Icons.album_outlined,
                              size: 32.r,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.w),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subtitle.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.w),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 12.5.sp),
          ),
        ],
      ),
    );
  }
}
