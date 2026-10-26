import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/ui/aura_loader.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart'
    as pb;

// Transport controls cluster (F04). Play/pause is the hero control with a
// soft glow; shuffle/repeat toggle to the accent when active.

/// Shuffle · previous · play/pause · next · repeat row.
final class PlayerControls extends StatelessWidget {
  /// Creates the controls.
  const PlayerControls({
    super.key,
    required this.accent,
    required this.status,
    required this.shuffle,
    required this.repeat,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
    this.busy = false,
  });

  /// Accent colour.
  final Color accent;

  /// Transport status.
  final pb.PlaybackStatus status;

  /// Shuffle active.
  final bool shuffle;

  /// Current repeat mode.
  final pb.RepeatMode repeat;

  /// Play/pause callback.
  final VoidCallback? onPlayPause;

  /// Next callback.
  final VoidCallback? onNext;

  /// Previous callback.
  final VoidCallback? onPrevious;

  /// Shuffle callback.
  final VoidCallback? onShuffle;

  /// Repeat callback.
  final VoidCallback? onRepeat;

  /// Shows a loading spinner on the hero button.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final playing = status == pb.PlaybackStatus.playing;
    final loading = busy || status == pb.PlaybackStatus.loading;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _toggle(
          icon: Icons.shuffle_rounded,
          tooltip: shuffle ? 'Shuffle on' : 'Shuffle off',
          active: shuffle,
          onPressed: onShuffle,
        ),
        IconButton(
          tooltip: 'Previous',
          onPressed: onPrevious,
          iconSize: 40.r,
          color: Colors.white,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        _heroButton(playing, loading),
        IconButton(
          tooltip: 'Next',
          onPressed: onNext,
          iconSize: 40.r,
          color: Colors.white,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        _toggle(
          icon: repeat == pb.RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          tooltip: switch (repeat) {
            pb.RepeatMode.off => 'Repeat off',
            pb.RepeatMode.all => 'Repeat queue',
            pb.RepeatMode.one => 'Repeat one',
          },
          active: repeat != pb.RepeatMode.off,
          onPressed: onRepeat,
        ),
      ],
    );
  }

  Widget _toggle({
    required IconData icon,
    required String tooltip,
    required bool active,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: active ? accent : Colors.white70,
    );
  }

  Widget _heroButton(bool playing, bool loading) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: accent,
        shape: CircleBorder(),
        child: Semantics(
          button: true,
          label: playing ? 'Pause' : 'Play',
          child: InkWell(
            customBorder: CircleBorder(),
            // Stay tappable while buffering so a stall can always be paused.
            onTap: onPlayPause,
            child: SizedBox(
              width: 72.w,
              height: 72.w,
              child: loading
                  ? Center(
                      child: AuraLoader(size: 34.r, color: Colors.black),
                    )
                  : Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 40.r,
                      color: Colors.black,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
