import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

/// Glass navigation rail for Medium+ (PRD 6.1).
/// Width 80 (compact rail) / 240 (extended), selected = accent pill.

/// Side rail with 4 tabs.
final class GlassRail extends StatelessWidget {
  /// Creates the rail. Set [extended] on Expanded/Large widths.
  const GlassRail({
    super.key,
    required this.shell,
    this.extended = false,
    this.tier = GlassTier.high,
  });

  /// Navigation shell to drive.
  final StatefulNavigationShell shell;

  /// Extended rail shows labels (width 240 vs 80).
  final bool extended;

  /// Glass tier.
  final GlassTier tier;

  /// Rail width with icons only.
  static const double compactWidth = 80;

  /// Rail width with icons + labels.
  static const double extendedWidth = 240;

  /// Outer margin around the rail card (each side).
  static const double railMargin = 12;

  /// Full box (card + margins) the shell must reserve for this rail. Lets the
  /// shell reveal the rail by clipping instead of squashing it.
  static double boxWidth({required bool extended}) =>
      (extended ? extendedWidth : compactWidth).w + railMargin.w * 2;

  static const _tabs = ['Home', 'Search', 'Library', 'Settings'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search,
    Icons.library_music_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Container(
        width: (extended ? extendedWidth : compactWidth).w,
        margin: EdgeInsets.all(railMargin.w),
        child: GlassSurface(
          borderRadius: 24.r,
          sigma: 24,
          tier: tier,
          padding: EdgeInsets.symmetric(vertical: 16.w),
          child: Column(
            mainAxisAlignment: extended
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceEvenly,
            children: List.generate(_tabs.length, (index) {
              final selected = shell.currentIndex == index;
              final pill = Container(
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? 16.w : 0,
                  vertical: 10.w,
                ),
                decoration: selected
                    ? BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16.r),
                      )
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: extended ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[index],
                      size: 22.r,
                      color: selected ? accent : null,
                    ),
                    if (extended) ...[
                      SizedBox(width: 12.w),
                      Text(_tabs[index]),
                    ],
                  ],
                ),
              );
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                child: InkWell(
                  onTap: () => shell.goBranch(index),
                  borderRadius: BorderRadius.circular(16.r),
                  child: pill,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
