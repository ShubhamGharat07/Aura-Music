import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Collection card for the library grid (PRD S12).

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
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface.fake(
      borderRadius: 20.r,
      padding: EdgeInsets.all(10.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: artUrl == null
                      ? Container(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.album,
                            size: 40.r,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: artUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            Icons.album,
                            size: 40.r,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.subtitle,
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
