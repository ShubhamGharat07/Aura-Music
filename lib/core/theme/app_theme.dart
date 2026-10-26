import 'package:flutter/material.dart';

import 'package:aura_music/core/theme/colors.dart';

/// Dark-first Material theme (PRD 8.2).
ThemeData buildDarkTheme({
  Color accent = AppColors.accentDefault,
  bool amoled = false,
}) {
  final bg = amoled ? AppColors.bgAmoled : AppColors.bg;
  final scheme = ColorScheme.dark(
    primary: accent,
    secondary: accent,
    surface: AppColors.bgElevated,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    splashFactory: InkSparkle.splashFactory,
    highlightColor: Colors.white.withValues(alpha: 0.04),
    splashColor: accent.withValues(alpha: 0.08),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SmoothPageTransitionsBuilder(),
        TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
        TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
        TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
        TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
        TargetPlatform.fuchsia: _SmoothPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.glassFill,
      side: const BorderSide(color: AppColors.glassBorder, width: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}

/// Soft fade + tiny rise for every pushed route (PRD 8.2 motion).
///
/// Falls back to no animation when the platform asks for reduced motion.
final class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  static final Animatable<double> _fadeTween = CurveTween(
    curve: Curves.easeOutCubic,
  );
  static final Animatable<Offset> _slideTween = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: Offset.zero,
  ).chain(CurveTween(curve: Curves.easeOutCubic));

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return FadeTransition(
      opacity: animation.drive(_fadeTween),
      child: SlideTransition(
        position: animation.drive(_slideTween),
        child: child,
      ),
    );
  }
}
