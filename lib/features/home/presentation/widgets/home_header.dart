import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Home top bar: the full Aura Music wordmark and one quiet History action.
///
/// The mark is the only continuously moving element on Home. It earns the
/// animation because it is the brand, sits on one tiny surface and stays inside
/// its own repaint boundary.
final class HomeHeader extends StatelessWidget {
  /// Creates the header.
  const HomeHeader({super.key, required this.padding});

  /// Horizontal inset from the window class.
  final double padding;

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 500;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        dense ? AppSpacing.sm : AppSpacing.md,
        padding,
        dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Row(
        children: [
          const _AuraMark(),
          SizedBox(width: 10.w),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Aura'),
                  TextSpan(
                    text: ' Music',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontVariations: const [FontVariation('wght', 400)],
                    ),
                  ),
                ],
              ),
              style: AppTypography.brand.copyWith(
                fontSize: dense ? 18.sp : 20.sp,
                letterSpacing: -0.35,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _HistoryButton(),
        ],
      ),
    );
  }
}

final class _AuraMark extends HookWidget {
  const _AuraMark();

  static const _heights = [9.0, 18.0, 12.0];

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1400),
    );

    useEffect(() {
      if (reduceMotion) {
        controller.value = 0.45;
      } else {
        controller.repeat();
      }
      return null;
    }, [controller, reduceMotion]);

    return RepaintBoundary(
      child: Semantics(
        label: 'Aura Music',
        child: ExcludeSemantics(
          child: SizedBox(
            width: 22.w,
            height: 24.w,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final t = controller.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _heights.length; i++) ...[
                      if (i > 0) SizedBox(width: 2.4.w),
                      Transform.scale(
                        scaleY:
                            0.55 +
                            0.45 *
                                math.sin(math.pi * ((t + i * 0.18) % 1)).abs(),
                        child: Container(
                          width: 2.6.w,
                          height: _heights[i].w,
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

final class _HistoryButton extends HookWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Tooltip(
      message: 'History',
      child: AnimatedScale(
        scale: pressed.value && !reduceMotion ? 0.92 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.out,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.glassBorder, width: 0.7),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              pressed.value = false;
              context.push(AppRoutes.history);
            },
            onHighlightChanged: (value) => pressed.value = value,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.out,
              width: 40.w,
              height: 40.w,
              color: pressed.value
                  ? AppColors.textPrimary.withValues(alpha: 0.07)
                  : Colors.transparent,
              child: AnimatedRotation(
                turns: pressed.value && !reduceMotion ? -0.045 : 0,
                duration: AppDurations.fast,
                curve: AppCurves.out,
                child: Icon(
                  Icons.history_rounded,
                  size: 20.r,
                  color: pressed.value
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
