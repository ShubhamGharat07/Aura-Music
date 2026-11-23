import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/theme/tokens.dart';

/// Play / pause glyph that morphs between the two states.
///
/// A cross-fade reads as two different buttons; the [AnimatedIcons.play_pause]
/// morph reads as one control changing state. Loading swaps to a spinner.
final class AnimatedPlayPauseIcon extends HookWidget {
  /// Creates the morphing icon.
  const AnimatedPlayPauseIcon({
    super.key,
    required this.playing,
    required this.size,
    required this.color,
    this.loading = false,
    this.loadingIndicator,
  });

  /// Whether the player is playing.
  final bool playing;

  /// Icon size.
  final double size;

  /// Icon tint.
  final Color color;

  /// Shows [loadingIndicator] instead of the glyph.
  final bool loading;

  /// Custom spinner (defaults to a 2 px circular indicator).
  final Widget? loadingIndicator;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: AppDurations.fast,
      initialValue: playing ? 1 : 0,
    );
    useEffect(() {
      if (reduceMotion) {
        controller.value = playing ? 1 : 0;
      } else {
        controller.animateTo(
          playing ? 1 : 0,
          duration: AppDurations.fast,
          curve: AppCurves.out,
        );
      }
      return null;
    }, [controller, playing, reduceMotion]);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      switchInCurve: AppCurves.out,
      switchOutCurve: AppCurves.out,
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: size,
              height: size,
              child: Center(
                child:
                    loadingIndicator ??
                    SizedBox(
                      width: size * 0.6,
                      height: size * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
              ),
            )
          : AnimatedIcon(
              key: const ValueKey('play-pause'),
              icon: AnimatedIcons.play_pause,
              progress: controller,
              size: size,
              color: color,
              semanticLabel: playing ? 'Pause' : 'Play',
            ),
    );
  }
}
