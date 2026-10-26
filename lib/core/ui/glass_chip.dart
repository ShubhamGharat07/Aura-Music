import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Selectable glass chip (PRD 8.3). Used by Moods & genres and filters.
final class GlassChip extends StatelessWidget {
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
    final accent = Theme.of(context).colorScheme.primary;
    return GlassSurface.fake(
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: selected
                ? accent.withValues(alpha: 0.18)
                : Colors.transparent,
            border: selected
                ? Border.all(color: accent.withValues(alpha: 0.45), width: 0.8)
                : null,
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 7.h,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15.r,
                  color: selected ? accent : AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
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
    );
  }
}
