import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/typography.dart';

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
    fontFamily: 'Manrope',
    colorScheme: scheme,
    textTheme: TextTheme(
      displayLarge: AppTypography.hero,
      displayMedium: AppTypography.display,
      displaySmall: AppTypography.display.copyWith(fontSize: 28.sp),
      headlineLarge: AppTypography.title,
      headlineMedium: AppTypography.title,
      headlineSmall: AppTypography.subtitle,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.subtitle,
      titleSmall: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body.copyWith(fontSize: 14.5.sp),
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      labelMedium: AppTypography.caption,
      labelSmall: AppTypography.overline,
    ),
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
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: AppTypography.title,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.glassFill,
      side: const BorderSide(color: AppColors.glassBorder, width: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.textPrimary.withValues(alpha: 0.88)
            : AppColors.glassFill,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.glassBorder),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.bg
            : AppColors.textSecondary,
      ),
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
