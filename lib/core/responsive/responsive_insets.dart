import 'package:aura_music/core/responsive/window_size_class.dart';

/// Side padding by window class (PRD 7.5): 16 / 24 / 32 / 40.

/// Responsive horizontal insets. Pure + testable.
abstract final class ResponsiveInsets {
  /// Side padding for a class.
  static double side(WindowSizeClass c) => switch (c) {
    WindowSizeClass.compact => 16,
    WindowSizeClass.medium => 24,
    WindowSizeClass.expanded => 32,
    WindowSizeClass.large => 40,
  };
}
