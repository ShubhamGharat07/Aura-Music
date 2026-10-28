import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Branded loading indicator (PRD Section 14).
///
/// A row of equaliser bars breathing in a phase-shifted loop. One controller
/// drives every bar, only heights change, and reduce-motion renders a static
/// resting pose. This is the same gesture as the wordmark.
final class AuraLoader extends HookWidget {
  /// Creates the loader.
  const AuraLoader({
    super.key,
    this.size = 44,
    this.color,
    this.barCount = 5,
    this.label,
  });

  /// Overall square size.
  final double size;

  /// Bar colour (defaults to the monochrome primary text colour).
  final Color? color;

  /// Number of bars.
  final int barCount;

  /// Optional caption under the bars.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );
    useEffect(() {
      if (reduceMotion) {
        controller.value = 0.35;
      } else {
        controller.repeat();
      }
      return null;
    }, [controller, reduceMotion]);

    final tint = color ?? AppColors.textPrimary;
    final barWidth = size / (barCount * 2.15);

    return Semantics(
      label: label ?? 'Loading',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: RepaintBoundary(
              child: SizedBox(
                width: size,
                height: size,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < barCount; i++)
                        Container(
                          width: barWidth,
                          height:
                              size *
                              (0.24 +
                                  0.68 *
                                      _level(
                                        controller.value,
                                        i,
                                        barCount,
                                        reduceMotion,
                                      )),
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            SizedBox(height: 14.w),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontSize: 12.5.sp,
                color: AppColors.textSecondary,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _level(double t, int index, int count, bool reduceMotion) {
    if (reduceMotion) return 0.5;
    final phase = t + index / count;
    return (math.sin(phase * 2 * math.pi) + 1) / 2;
  }
}
