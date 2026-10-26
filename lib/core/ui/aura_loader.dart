import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/theme/tokens.dart';

// Branded loading indicator (PRD Section 14). A row of equaliser bars that
// breathe in a phase-shifted loop — it reads as "music loading" and suits the
// app far better than a generic spinner. One controller drives every bar, so
// it stays cheap, and reduce-motion renders it as a static resting pose.

/// Animated equaliser loading indicator.
final class AuraLoader extends HookWidget {
  /// Creates the loader.
  const AuraLoader({super.key, this.size = 44, this.color, this.barCount = 4});

  /// Overall square size (widest bar height fits inside).
  final double size;

  /// Bar colour (defaults to the theme primary).
  final Color? color;

  /// Number of bars.
  final int barCount;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );
    useEffect(() {
      if (!reduceMotion) controller.repeat();
      return null;
    }, [reduceMotion]);

    final tint = color ?? Theme.of(context).colorScheme.primary;
    final barWidth = size / (barCount * 1.7);

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < barCount; i++)
              _Bar(
                height:
                    size *
                    (0.32 +
                        0.68 *
                            _level(
                              controller.value,
                              i,
                              barCount,
                              reduceMotion,
                            )),
                width: barWidth,
                color: tint,
              ),
          ],
        ),
      ),
    );
  }

  double _level(double t, int index, int count, bool reduceMotion) {
    if (reduceMotion) return 0.5;
    final phase = t + index / count;
    return (math.sin(phase * 2 * math.pi) + 1) / 2;
  }
}

final class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.width, required this.color});

  final double height;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
