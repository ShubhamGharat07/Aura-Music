import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/utils/format_count.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Ranked "Suggestions" row (PRD S04): a chart position and play count on the
/// left, artwork on the right. Tap plays the track.

/// Ranked suggestion row.
final class SuggestionTile extends StatelessWidget {
  /// Creates a suggestion tile.
  const SuggestionTile({
    super.key,
    required this.rank,
    required this.track,
    this.onTap,
  });

  /// 1-based chart position.
  final int rank;

  /// Backing track.
  final Track track;

  /// Tap = play.
  final VoidCallback? onTap;

  static const double _artSize = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.w, horizontal: 2.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: AppTypography.subtitle.copyWith(
                            fontSize: 16.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3.w),
                        Text(
                          track.artist,
                          style: AppTypography.caption.copyWith(
                            fontSize: 13.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.w),
                        Text(
                          '#$rank  ${formatCompactCount(track.playCount)} plays',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.art),
                    child: SizedBox(
                      width: _artSize,
                      height: _artSize,
                      child: track.artUrl == null
                          ? ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: track.artUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 128,
                              memCacheHeight: 128,
                              fadeInDuration: Duration.zero,
                              errorWidget: (context, _, _) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(
          height: 0.6,
          thickness: 0.6,
          color: AppColors.glassBorder,
        ),
      ],
    );
  }
}
