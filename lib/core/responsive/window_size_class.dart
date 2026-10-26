import 'package:flutter/widgets.dart';

import 'package:aura_music/core/responsive/breakpoints.dart';

/// Window size class from available width (PRD 7.1).
/// Derived from constraints / MediaQuery, never from [Platform].

/// Navigation chrome selected for the current logical window.
enum ShellNavigationMode {
  /// Floating bottom navigation bar (compact width).
  bottomBar,

  /// 80 dp icon rail (medium width, or any compact-height window).
  compactRail,

  /// 240 dp labelled rail (expanded/large with enough height).
  extendedRail,
}

/// Material 3 width classes.
enum WindowSizeClass {
  /// Phones portrait, split-screen halves (< 600 dp).
  compact,

  /// Small tablets portrait, foldables unfolded (600-839 dp).
  medium,

  /// Tablets landscape (840-1199 dp).
  expanded,

  /// Large tablets / freeform windows (>= 1200 dp).
  large;

  /// Resolves a class from an available width. Pure + testable.
  static WindowSizeClass ofWidth(double width) {
    if (width >= kLargeBreakpoint) return WindowSizeClass.large;
    if (width >= kExpandedBreakpoint) return WindowSizeClass.expanded;
    if (width >= kMediumBreakpoint) return WindowSizeClass.medium;
    return WindowSizeClass.compact;
  }

  /// Resolves from the current context (MediaQuery width).
  static WindowSizeClass of(BuildContext context) =>
      WindowSizeClass.ofWidth(MediaQuery.sizeOf(context).width);

  /// True when height is below the compact-height threshold.
  static bool isCompactHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height < kCompactHeightBreakpoint;

  /// Chooses navigation chrome from logical window dimensions (PRD 6.1/7.2).
  static ShellNavigationMode navigationFor({
    required double width,
    required double height,
  }) {
    final size = ofWidth(width);
    if (size == WindowSizeClass.compact) return ShellNavigationMode.bottomBar;
    final wantsExtended =
        size == WindowSizeClass.expanded || size == WindowSizeClass.large;
    return wantsExtended && height >= kCompactHeightBreakpoint
        ? ShellNavigationMode.extendedRail
        : ShellNavigationMode.compactRail;
  }
}

/// Convenience getters.
extension WindowSizeClassX on WindowSizeClass {
  /// Compact or smaller.
  bool get isCompact => this == WindowSizeClass.compact;

  /// Medium or larger.
  bool get isMediumUp => this != WindowSizeClass.compact;

  /// Expanded or larger (rail + panel layouts).
  bool get isExpandedUp =>
      this == WindowSizeClass.expanded || this == WindowSizeClass.large;
}
