import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Floating glass bottom bar for Compact (PRD 6.1).
/// Height 64, bottom margin 12, side margin 16, radius 32, sigma 28.

/// Bottom navigation with 4 tabs: Home · Search · Library · Settings.
final class GlassNavBar extends StatelessWidget {
  /// Creates the bottom bar.
  const GlassNavBar({
    super.key,
    required this.shell,
    this.tier = GlassTier.high,
  });

  /// Navigation shell to drive.
  final StatefulNavigationShell shell;

  /// Glass tier.
  final GlassTier tier;

  static const _tabs = ['Home', 'Search', 'Library', 'Settings'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search_rounded,
    Icons.library_music_outlined,
    Icons.settings_outlined,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.library_music_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.w),
        child: SizedBox(
          height: 64.w,
          child: GlassSurface(
            borderRadius: 32.r,
            sigma: 28,
            tier: tier,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.w),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final selected = shell.currentIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => shell.goBranch(
                      index,
                      initialLocation: index == shell.currentIndex,
                    ),
                    borderRadius: BorderRadius.circular(26.r),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26.r),
                        color: selected
                            ? accent.withValues(alpha: 0.14)
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selected ? _activeIcons[index] : _icons[index],
                            size: 22.r,
                            color: selected ? accent : AppColors.textSecondary,
                          ),
                          SizedBox(height: 3.w),
                          Text(
                            _tabs[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.sp,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
