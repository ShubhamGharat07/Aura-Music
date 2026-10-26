import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/utils/format_count.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Ranked "Suggestions" row (PRD S04): a chart position and play count on the
/// left, artwork on the right. Tap plays the track.

/// Ranked suggestion card.
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
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      track.artist,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '#$rank  ${formatCompactCount(track.playCount)} plays',
                      style: AppTypography.caption.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
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
    );
  }
}
