import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';

/// Shimmering placeholders for sections that are still loading (PRD 8.2).
///
/// One [Shimmer] drives every [Skeleton] below it from a single controller, so
/// a whole grid sweeps on one ticker, and each [Skeleton] repaints inside its
/// own [RepaintBoundary] so the animated highlight never dirties the rest of
/// the feed.

/// Drives the shimmer sweep for every [Skeleton] in its subtree.
final class Shimmer extends HookWidget {
  /// Creates a shimmer scope.
  const Shimmer({super.key, required this.child});

  /// Placeholder subtree.
  final Widget child;

  /// Length of one left-to-right sweep.
  static const Duration period = Duration(milliseconds: 1200);

  /// The running sweep for [context], or null outside a [Shimmer].
  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(duration: period);
    useEffect(() {
      if (reduceMotion) {
        controller.value = 0;
      } else {
        controller.repeat();
      }
      return null;
    }, [controller, reduceMotion]);
    return _ShimmerScope(animation: controller, child: child);
  }
}

final class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  // Dependents listen to the controller through AnimatedBuilder, so the scope
  // itself never has to notify them.
  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// One placeholder tile: a glass card that shimmers while inside a [Shimmer].
///
/// Without a [Shimmer] ancestor it draws as a static tile, so skeletons stay
/// usable in tests and one-off cases with no animation running.
final class Skeleton extends StatelessWidget {
  /// Creates a skeleton tile.
  const Skeleton({super.key, this.width, this.height, this.borderRadius});

  /// Fixed width (null keeps the incoming constraint).
  final double? width;

  /// Fixed height (null keeps the incoming constraint).
  final double? height;

  /// Corner radius (defaults to the artwork radius).
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.art);
    final shimmer = Shimmer.maybeOf(context);
    // No size given -> fill the slot (grid cells), like the tiles it replaces.
    final box = width == null && height == null
        ? const SizedBox.expand()
        : SizedBox(width: width, height: height);
    if (shimmer == null) return _tile(radius, null, box);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: shimmer,
        child: box,
        builder: (context, child) =>
            _tile(radius, _sweep(shimmer.value), child!),
      ),
    );
  }

  Widget _tile(BorderRadius radius, Gradient? sweep, Widget child) => Container(
    decoration: BoxDecoration(
      color: AppColors.bgElevated,
      borderRadius: radius,
      border: Border.all(color: AppColors.glassBorder, width: 0.6),
    ),
    foregroundDecoration: sweep == null
        ? null
        : BoxDecoration(borderRadius: radius, gradient: sweep),
    child: child,
  );

  /// The highlight band sweeping left to right across the tile.
  Gradient _sweep(double t) => LinearGradient(
    begin: Alignment(-1.8 + 3.2 * t, -0.25),
    end: Alignment(-0.8 + 3.2 * t, 0.25),
    colors: [
      AppColors.bgElevated.withValues(alpha: 0),
      AppColors.glassBorder,
      AppColors.bgElevated.withValues(alpha: 0),
    ],
  );
}
