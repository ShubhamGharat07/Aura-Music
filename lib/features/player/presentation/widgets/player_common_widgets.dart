import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/widgets/player_action.dart';
import 'package:aura_music/features/player/presentation/widgets/sleep_timer_action.dart';

// Shared building blocks for all Now Playing layouts (S06).

/// Top bar: collapse, centred caption, listen together, overflow menu.
final class PlayerHeader extends StatelessWidget {
  /// Creates the header.
  const PlayerHeader({
    super.key,
    this.onCollapse,
    this.onParty,
    this.partyActive = false,
    this.onMore,
  });

  /// Collapse (back) callback.
  final VoidCallback? onCollapse;

  /// Listen together callback (shares or follows a session, PRD S06).
  /// Receives the button's own context so the popover can anchor to it.
  final ValueChanged<BuildContext>? onParty;

  /// Whether a party session is running (accent-tinted button).
  final bool partyActive;

  /// Overflow menu callback.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onCollapse,
          icon: Icon(Icons.expand_more_rounded, size: 30.r),
        ),
        Expanded(
          child: Center(
            child: Text(
              'NOW PLAYING',
              style: AppTypography.overline.copyWith(
                letterSpacing: 1.8,
                fontSize: 9.5.sp,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        Builder(
          builder: (context) => IconButton(
            onPressed: onParty == null ? null : () => onParty!(context),
            tooltip: 'Listen together',
            color: partyActive ? Theme.of(context).colorScheme.primary : null,
            icon: Icon(
              partyActive
                  ? Icons.bluetooth_connected_rounded
                  : Icons.bluetooth_rounded,
            ),
          ),
        ),
        IconButton(
          onPressed: onMore,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

/// Title, artist and like button.
final class TrackInfo extends StatelessWidget {
  /// Creates track info.
  const TrackInfo({
    super.key,
    required this.track,
    required this.liked,
    required this.accent,
    this.onLike,
    this.centered = false,
  });

  /// Current track.
  final Track track;

  /// Whether the track is liked.
  final bool liked;

  /// Accent colour.
  final Color accent;

  /// Like toggle callback.
  final VoidCallback? onLike;

  /// Center-aligns the text (compact/medium); left-aligned in landscape.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                track.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: AppTypography.display.copyWith(
                  fontSize: 27.sp,
                  height: 1.18,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            IconButton(
              onPressed: onLike,
              iconSize: 21.r,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: 32.w, height: 32.w),
              color: liked ? accent : AppColors.textSecondary,
              icon: Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          track.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Bottom action row: lyrics, queue, download, sleep timer. Equal-weight items
/// so it never overflows on narrow phones.
final class BottomActions extends StatelessWidget {
  /// Creates the bottom actions.
  const BottomActions({
    super.key,
    this.onLyrics,
    this.onQueue,
    this.onDownload,
  });

  /// Lyrics callback.
  final VoidCallback? onLyrics;

  /// Queue callback.
  final VoidCallback? onQueue;

  /// Download callback.
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PlayerAction(
            icon: Icons.lyrics_outlined,
            label: 'Lyrics',
            onTap: onLyrics,
          ),
        ),
        Expanded(
          child: PlayerAction(
            icon: Icons.queue_music_outlined,
            label: 'Queue',
            onTap: onQueue,
          ),
        ),
        Expanded(
          child: PlayerAction(
            icon: Icons.download_outlined,
            label: 'Download',
            onTap: onDownload,
          ),
        ),
        const Expanded(child: SleepTimerAction()),
      ],
    );
  }
}

/// Empty state shown before anything is playing.
final class PlayerEmptyState extends StatelessWidget {
  /// Creates the empty state.
  const PlayerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note_rounded, size: 72.r, color: Colors.white54),
            SizedBox(height: AppSpacing.lg),
            Text('Nothing playing', style: AppTypography.title),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Pick a song from Home, Search or Library to start listening.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
