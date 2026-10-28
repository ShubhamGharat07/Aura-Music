import 'package:flutter/animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing / radius / motion / layout tokens (PRD 8.2).
/// Widgets must use these instead of magic numbers.

/// 4-pt spacing grid (scaled with ScreenUtil).
abstract final class AppSpacing {
  /// 4 dp.
  static double get xs => 4.w;

  /// 8 dp.
  static double get sm => 8.w;

  /// 12 dp.
  static double get md => 12.w;

  /// 16 dp.
  static double get lg => 16.w;

  /// 24 dp.
  static double get xl => 24.w;

  /// 32 dp.
  static double get xxl => 32.w;
}

/// Refined architectural corner radii (less bubbly, more pro).
abstract final class AppRadius {
  /// Chips & compact tiles.
  static double get chip => 10.r;

  /// Cards & list tiles.
  static double get card => 16.r;

  /// Bottom sheets.
  static double get sheet => 32.r;

  /// Album art in carousels/lists.
  static double get art => 14.r;

  /// Album art on the full player.
  static double get artPlayer => 24.r;

  /// Pills / floating bars.
  static double get pill => 999.r;
}

/// Motion curves shared by every component (PRD 8.2).
///
/// The built-in `Curves.easeOut*` curves are too soft for UI chrome: these
/// start faster and settle sooner, so a 200 ms transition reads as instant
/// feedback instead of a fade.
abstract final class AppCurves {
  /// Entering / responding to the user.
  static const Curve out = Cubic(0.23, 1, 0.32, 1);

  /// Elements already on screen moving from A to B.
  static const Curve inOut = Cubic(0.77, 0, 0.175, 1);

  /// Sheets and drawers (iOS-like).
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);
}

/// Motion durations (easeOutCubic, PRD 8.2).
abstract final class AppDurations {
  /// Micro interactions (fade, chip select).
  static const Duration fast = Duration(milliseconds: 120);

  /// Standard transitions (bar hide, panel open).
  static const Duration medium = Duration(milliseconds: 220);

  /// Large transitions (now-playing expand).
  static const Duration slow = Duration(milliseconds: 360);

  /// Dynamic-colour tween.
  static const Duration colorTween = Duration(milliseconds: 400);
}

/// Layout clamps.
abstract final class AppLayout {
  /// Default max content width on Expanded/Large.
  static const double maxContentWidth = 1200;

  /// Max width for reading text (lyrics, about).
  static const double maxReadingWidth = 720;

  /// Settings master pane width.
  static const double settingsMasterWidth = 320;

  /// Side panel width range (queue / lyrics on tablets).
  static const double sidePanelMin = 360;

  /// Side panel width range (queue / lyrics on tablets).
  static const double sidePanelMax = 420;
}
