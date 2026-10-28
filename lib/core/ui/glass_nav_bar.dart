import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Floating glass bottom bar for Compact (PRD 6.1).
///
/// A single monochrome well slides between tabs while the icon swaps inside it.
/// Chrome stays neutral; colour is left to the artwork above it.

/// Bottom navigation with 4 tabs: Home / Search / Library / Settings.
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion ? Duration.zero : AppDurations.slow;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.w),
        child: SizedBox(
          height: 66.w,
          child: GlassSurface(
            borderRadius: 26.r,
            sigma: 24,
            tier: tier,
            padding: EdgeInsets.all(6.w),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _tabs.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: duration,
                      curve: AppCurves.inOut,
                      left: slot * shell.currentIndex + (slot - 42.w) / 2,
                      top: 2.w,
                      width: 42.w,
                      height: 28.w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                            width: 0.6,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_tabs.length, (index) {
                        return Expanded(
                          child: _NavItem(
                            label: _tabs[index],
                            icon: _icons[index],
                            activeIcon: _activeIcons[index],
                            selected: shell.currentIndex == index,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              shell.goBranch(
                                index,
                                initialLocation: index == shell.currentIndex,
                              );
                            },
                          ),
                        );
                      }),
                    ),
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

final class _NavItem extends HookWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.94 : 1,
      duration: AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => pressed.value = value,
          borderRadius: BorderRadius.circular(14.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : AppDurations.fast,
                switchInCurve: AppCurves.out,
                switchOutCurve: AppCurves.out,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.84,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  size: 21.r,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.w),
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                curve: AppCurves.out,
                style: AppTypography.caption.copyWith(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: -0.05,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
