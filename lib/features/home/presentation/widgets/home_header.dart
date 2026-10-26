import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Home top bar (PRD S03): Bold "Aura Music" brand header + History action.
final class HomeHeader extends StatelessWidget {
  /// Creates the header.
  const HomeHeader({super.key, required this.padding});

  /// Horizontal inset from the window class.
  final double padding;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final dense = MediaQuery.sizeOf(context).height < 500;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        dense ? AppSpacing.sm : AppSpacing.lg,
        padding,
        dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sleek minimal brand emblem
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.55)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.bg,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Aura Music',
              style: AppTypography.display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          GlassSurface.fake(
            borderRadius: AppRadius.pill,
            child: SizedBox(
              width: 42.w,
              height: 42.w,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'History',
                onPressed: () => context.push(AppRoutes.history),
                icon: Icon(
                  Icons.history_rounded,
                  color: AppColors.textPrimary,
                  size: 20.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
