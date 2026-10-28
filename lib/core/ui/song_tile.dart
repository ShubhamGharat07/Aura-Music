import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/download_button.dart';
import 'package:aura_music/features/library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Song row (PRD 7.5). Fake glass only: never a blur inside scroll items.

/// Song list tile. Art 52 (compact) / 56 (medium+).
final class SongTile extends StatelessWidget {
  /// Creates a song tile.
  const SongTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.artUrl,
    this.track,
    this.trailing,
    this.onTap,
    this.compact = true,
  });

  /// Track title.
  final String title;

  /// Artist · album line.
  final String subtitle;

  /// Artwork URL (null = placeholder).
  final String? artUrl;

  /// Track backing this row; when set an inline download button is shown.
  final Track? track;

  /// Trailing slot (duration, like button).
  final Widget? trailing;

  /// Tap = play.
  final VoidCallback? onTap;

  /// Compact art size (52) vs medium+ (56).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final art = compact ? 56.0 : 60.0;
    final current = track;
    final effectiveTrailing = current == null
        ? trailing
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?trailing,
              IconButton(
                tooltip: 'Add to playlist',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.playlist_add),
                onPressed: () => showAddToPlaylist(context, current),
              ),
              DownloadButton(track: current),
            ],
          );
    return ListTile(
      onTap: onTap,
      minVerticalPadding: 8,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: artUrl == null
            ? SizedBox(
                width: art,
                height: art,
                child: const Icon(Icons.music_note),
              )
            : CachedNetworkImage(
                imageUrl: artUrl!,
                width: art,
                height: art,
                memCacheWidth: 120,
                memCacheHeight: 120,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => SizedBox(
                  width: art,
                  height: art,
                  child: const Icon(Icons.music_note),
                ),
              ),
      ),
      title: Text(
        title,
        style: AppTypography.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: effectiveTrailing,
    );
  }
}
