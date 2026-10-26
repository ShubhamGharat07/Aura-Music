import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';

/// Playlist hero header (PRD S11): artwork, title, meta and Play all.

/// Playlist header (single column on compact, two columns otherwise).
final class PlaylistHeader extends StatelessWidget {
  /// Creates a playlist header.
  const PlaylistHeader({
    super.key,
    required this.playlist,
    required this.songCount,
    this.onPlayAll,
  });

  /// Playlist metadata.
  final Playlist playlist;

  /// Number of songs.
  final int songCount;

  /// Plays the playlist from the top.
  final VoidCallback? onPlayAll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final art = compact ? 140.0 : 200.0;
        final artWidget = ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(width: art, height: art, child: _art()),
        );
        final info = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              playlist.title,
              style: AppTypography.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: compact ? TextAlign.center : TextAlign.start,
            ),
            SizedBox(height: 6.w),
            Text(
              _meta(),
              style: AppTypography.caption,
              textAlign: compact ? TextAlign.center : TextAlign.start,
            ),
            SizedBox(height: 16.w),
            FilledButton.icon(
              onPressed: onPlayAll,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play all'),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.only(top: 8.w, bottom: 16.w),
          child: compact
              ? Column(
                  children: [
                    artWidget,
                    SizedBox(height: 16.w),
                    info,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artWidget,
                    SizedBox(width: 24.w),
                    Expanded(child: info),
                  ],
                ),
        );
      },
    );
  }

  String _meta() => [
    if (playlist.subtitle != null) playlist.subtitle!,
    '$songCount songs',
  ].join(' · ');

  Widget _art() {
    final url = playlist.artUrl;
    if (url == null) {
      return ColoredBox(
        color: Color(0xFF1A2030),
        child: Icon(Icons.queue_music_outlined, size: 48.r),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      errorWidget: (context, errorUrl, error) => ColoredBox(
        color: Color(0xFF1A2030),
        child: Icon(Icons.queue_music_outlined, size: 48.r),
      ),
    );
  }
}
