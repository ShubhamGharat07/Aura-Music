import 'package:flutter/material.dart';

/// BuildContext conveniences (PRD 5.3: no logic in build, but reading
/// theme/media is fine). Import instead of reaching into Theme.of chains.
extension ContextX on BuildContext {
  /// Current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Current [ColorScheme].
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Current [TextTheme].
  TextTheme get texts => Theme.of(this).textTheme;

  /// Logical screen size (from MediaQuery).
  Size get screenSize => MediaQuery.sizeOf(this);

  /// True when the OS requests reduced motion (PRD 8.6).
  bool get prefersReducedMotion => MediaQuery.disableAnimationsOf(this);
}
