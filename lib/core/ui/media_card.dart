import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Media card for albums / artists / playlists (PRD 7.5).
final class MediaCard extends StatelessWidget {
  /// Creates a media card.
  const MediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.artUrl,
    this.onTap,
  });

  /// Card title.
  final String title;

  /// Card subtitle.
  final String subtitle;

  /// Artwork URL.
  final String? artUrl;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.art);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: AppColors.bgElevated,
                border: Border.all(color: AppColors.glassBorder, width: 0.6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: artUrl == null
                    ? ColoredBox(
                        color: AppColors.bgElevated,
                        child: Icon(
                          Icons.album_outlined,
                          color: AppColors.textTertiary,
                          size: 32.r,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: artUrl!,
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                        fit: BoxFit.cover,
                        fadeInDuration: AppDurations.fast,
                        placeholder: (context, url) =>
                            const ColoredBox(color: AppColors.bgElevated),
                        errorWidget: (context, url, error) => ColoredBox(
                          color: AppColors.bgElevated,
                          child: Icon(
                            Icons.album_outlined,
                            color: AppColors.textTertiary,
                            size: 32.r,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.subtitle.copyWith(fontSize: 13.5.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
