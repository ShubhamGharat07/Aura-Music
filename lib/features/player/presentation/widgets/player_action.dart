import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// One icon + label cell used by the Now Playing action row (PRD S06).

/// Player action cell.
final class PlayerAction extends StatelessWidget {
  /// Creates a player action.
  const PlayerAction({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  /// Leading icon.
  final IconData icon;

  /// Caption under the icon.
  final String label;

  /// Tap callback (null = non-interactive).
  final VoidCallback? onTap;

  /// Overrides the idle white70 tint (used for an armed sleep timer).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23.r, color: tint),
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
