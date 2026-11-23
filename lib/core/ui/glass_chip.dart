import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Selectable glass chip (PRD 8.3). Used by Moods & genres and filters.
final class GlassChip extends HookWidget {
  /// Creates a glass chip.
  const GlassChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.onRemove,
    this.tier = GlassTier.low,
  });

  /// Chip label.
  final String label;

  /// Selected state (accent pill).
  final bool selected;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing remove action (recent-search chips).
  final VoidCallback? onRemove;

  /// Glass tier (fake by default: chips live in scroll lists).
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scale = reduceMotion
        ? 1.0
        : pressed.value
        ? 0.97
        : selected
        ? 1.02
        : 1.0;
    return AnimatedScale(
      scale: scale,
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: AppCurves.out,
      child: Semantics(
        selected: onTap == null ? null : selected,
        child: GlassSurface.fake(
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            onHighlightChanged: (value) => pressed.value = value,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppDurations.fast,
              curve: AppCurves.out,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: selected
                    ? AppColors.textPrimary.withValues(alpha: 0.10)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.textPrimary.withValues(alpha: 0.24)
                      : AppColors.glassBorder,
                  width: 0.7,
                ),
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16.r,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 14.5.sp,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (onRemove != null) ...[
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14.r,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
