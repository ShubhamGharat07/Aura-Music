import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
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
    final tap = onLike;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
              tooltip: liked ? 'Unlike' : 'Like',
              onPressed: tap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      tap();
                    },
              iconSize: 21.r,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: 32.w, height: 32.w),
              icon: AnimatedSwitcher(
                key: ValueKey(track.id),
                duration: reduceMotion ? Duration.zero : AppDurations.fast,
                switchInCurve: AppCurves.out,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(Tween(begin: 0.88, end: 1.0)),
                    child: child,
                  ),
                ),
                child: Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(liked),
                  color: liked ? accent : AppColors.textSecondary,
                ),
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
    this.trackId,
  });

  /// Lyrics callback.
  final VoidCallback? onLyrics;

  /// Queue callback.
  final VoidCallback? onQueue;

  /// Download callback.
  final VoidCallback? onDownload;

  /// Track whose offline availability is displayed by the download action.
  final String? trackId;

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
          child: _DownloadAction(trackId: trackId, onTap: onDownload),
        ),
        const Expanded(child: SleepTimerAction()),
      ],
    );
  }
}

final class _DownloadAction extends StatelessWidget {
  const _DownloadAction({required this.trackId, required this.onTap});

  final String? trackId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = context.select<DownloadsCubit?, (IconData, String)>((
      cubit,
    ) {
      final downloads = cubit?.state.downloads ?? const [];
      for (final download in downloads) {
        if (download.track.id != trackId) continue;
        if (download.isComplete) {
          return (Icons.download_done_rounded, 'Offline');
        }
        if (download.isActive) {
          return (Icons.downloading_rounded, 'Downloading');
        }
      }
      return (Icons.download_outlined, 'Download');
    });
    return PlayerAction(
      key: ValueKey(trackId),
      icon: icon,
      label: label,
      onTap: onTap,
      animate: true,
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
