import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/seek_bar.dart';

/// Persistent player bar for Expanded/Large (PRD 6.1 + O6).
/// Presentational only: playback state is wired in Phase 1 via
/// [PlayerBloc] + position [ValueListenable]. No `setState`.
final class PlayerBar extends HookWidget {
  /// Creates a player bar.
  const PlayerBar({
    super.key,
    required this.position,
    required this.duration,
    this.title,
    this.subtitle,
    this.artUrl,
    this.isPlaying = false,
    this.busy = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onSeek,
    this.onExpand,
    this.tier = GlassTier.mid,
  });

  /// Playback position notifier.
  final ValueListenable<Duration> position;

  /// Track total duration.
  final Duration duration;

  /// Track title (null = nothing playing).
  final String? title;

  /// Artist · album.
  final String? subtitle;

  /// Artwork URL.
  final String? artUrl;

  /// Whether playback is running.
  final bool isPlaying;

  /// Whether the track is loading / buffering.
  final bool busy;

  /// Play/pause callback.
  final VoidCallback? onPlayPause;

  /// Next track.
  final VoidCallback? onNext;

  /// Previous track.
  final VoidCallback? onPrevious;

  /// Seek callback.
  final ValueChanged<Duration>? onSeek;

  /// Expand to full player.
  final VoidCallback? onExpand;

  /// Glass tier.
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final idle = title == null;
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: GlassSurface(
        borderRadius: AppRadius.card,
        tier: tier,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _Art(url: artUrl),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idle ? 'Nothing playing' : title!,
                    style: AppTypography.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    idle ? 'Search and press play' : (subtitle ?? ''),
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            _Controls(
              isPlaying: isPlaying,
              busy: busy,
              onPlayPause: idle ? null : onPlayPause,
              onNext: idle ? null : onNext,
              onPrevious: idle ? null : onPrevious,
            ),
            SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 220.w,
              child: SeekBar(
                position: position,
                duration: duration,
                onSeek: onSeek,
                showLabels: false,
              ),
            ),
            IconButton(
              onPressed: idle ? null : onExpand,
              icon: const Icon(Icons.expand_less),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Art extends StatelessWidget {
  const _Art({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.art / 2),
      child: SizedBox(
        width: 48.w,
        height: 48.w,
        child: url == null
            ? Container(
                color: const Color(0xFF1A2030),
                child: Icon(Icons.music_note, size: 22.r),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 96,
                errorWidget: (context, _, _) => Container(
                  color: const Color(0xFF1A2030),
                  child: Icon(Icons.music_note, size: 22.r),
                ),
              ),
      ),
    );
  }
}

final class _Controls extends StatelessWidget {
  const _Controls({
    required this.isPlaying,
    this.busy = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
  });

  final bool isPlaying;
  final bool busy;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous',
          onPressed: onPrevious,
          icon: const Icon(Icons.skip_previous),
        ),
        if (busy)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          IconButton(
            tooltip: isPlaying ? 'Pause' : 'Play',
            onPressed: onPlayPause,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 36.r,
            ),
          ),
        IconButton(
          tooltip: 'Next',
          onPressed: onNext,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}
