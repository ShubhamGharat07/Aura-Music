import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';

/// Artist hero header (PRD S10): circular portrait, name, followers, Play.

/// Artist header.
final class ArtistHeader extends StatelessWidget {
  /// Creates an artist header.
  const ArtistHeader({
    super.key,
    required this.artist,
    this.followerCount,
    this.onPlay,
  });

  /// Artist metadata.
  final Artist artist;

  /// Follower count, when known.
  final int? followerCount;

  /// Plays the artist's top songs.
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.w, bottom: 16.w),
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(width: 140.w, height: 140.w, child: _portrait()),
          ),
          SizedBox(height: 16.w),
          Text(
            artist.name,
            style: AppTypography.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (followerCount != null) ...[
            SizedBox(height: 4.w),
            Text(
              '${_followers(followerCount!)} followers',
              style: AppTypography.caption,
            ),
          ],
          SizedBox(height: 16.w),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ],
      ),
    );
  }

  String _followers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  Widget _portrait() {
    final url = artist.imageUrl;
    if (url == null) {
      return ColoredBox(
        color: Color(0xFF1A2030),
        child: Icon(Icons.person_outline, size: 64.r),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 300,
      errorWidget: (context, errorUrl, error) => ColoredBox(
        color: Color(0xFF1A2030),
        child: Icon(Icons.person_outline, size: 64.r),
      ),
    );
  }
}
