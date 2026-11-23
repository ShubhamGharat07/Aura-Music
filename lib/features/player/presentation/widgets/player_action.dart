import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// One icon + label cell used by the Now Playing action row (PRD S06).

/// Player action cell.
final class PlayerAction extends HookWidget {
  /// Creates a player action.
  const PlayerAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.animate = false,
  });

  /// Leading icon.
  final IconData icon;

  /// Caption under the icon.
  final String label;

  /// Tap callback (null = non-interactive).
  final VoidCallback? onTap;

  /// Overrides the idle white70 tint (used for an armed sleep timer).
  final Color? color;

  /// Animate press feedback and a change of the action icon.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    final pressed = useState(false);
    final motion = animate && !MediaQuery.disableAnimationsOf(context);
    final glyph = Icon(icon, key: ValueKey(icon), size: 23.r, color: tint);
    return InkWell(
      onTap: onTap,
      onHighlightChanged: motion ? (value) => pressed.value = value : null,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (motion)
              AnimatedScale(
                scale: pressed.value ? 0.9 : 1,
                duration: AppDurations.fast,
                curve: AppCurves.out,
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  switchInCurve: AppCurves.out,
                  child: glyph,
                ),
              )
            else
              glyph,
            SizedBox(height: 8.w),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: tint,
                fontSize: 12.5.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
