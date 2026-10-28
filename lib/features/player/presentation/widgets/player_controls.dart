import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/aura_loader.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart'
    as pb;

// Transport controls cluster (F04). Play/pause is the one filled control;
// shuffle/repeat toggle to the accent when active.

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
          iconSize: 35.r,
          color: AppColors.textPrimary,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        _HeroButton(
          accent: accent,
          playing: playing,
          loading: loading,
          onPressed: onPlayPause,
        ),
        IconButton(
          tooltip: 'Next',
          onPressed: onNext,
          iconSize: 35.r,
          color: AppColors.textPrimary,
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
      iconSize: 22.r,
      icon: Icon(icon),
      color: active ? accent : AppColors.textSecondary,
    );
  }
}

/// Hero play/pause button with a tactile press cue and a crossfaded icon.
final class _HeroButton extends HookWidget {
  const _HeroButton({
    required this.accent,
    required this.playing,
    required this.loading,
    this.onPressed,
  });

  final Color accent;
  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.94 : 1,
      duration: AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: accent,
        shape: const CircleBorder(),
        child: Semantics(
          button: true,
          label: playing ? 'Pause' : 'Play',
          child: InkWell(
            customBorder: const CircleBorder(),
            // Stay tappable while buffering so a stall can always be paused.
            onTap: onPressed,
            onTapDown: (_) => pressed.value = true,
            onTapUp: (_) => pressed.value = false,
            onTapCancel: () => pressed.value = false,
            child: SizedBox(
              width: 60.w,
              height: 60.w,
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                switchInCurve: AppCurves.out,
                switchOutCurve: AppCurves.out,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(Tween<double>(begin: 0.92, end: 1)),
                    child: child,
                  ),
                ),
                child: loading
                    ? Center(
                        key: const ValueKey('loading'),
                        child: AuraLoader(size: 31.r, color: Colors.black),
                      )
                    : Icon(
                        key: ValueKey(playing),
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 32.r,
                        color: Colors.black,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
