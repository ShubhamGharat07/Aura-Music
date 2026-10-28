import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';

/// Aura's editorial type scale.
///
/// One family does the work: Manrope's closed apertures and even rhythm read
/// as a product, not a poster. Hierarchy comes from size, weight and space
/// rather than a second display face, which keeps every screen consistent.
abstract final class AppTypography {
  static const String _family = 'Manrope';

  /// Hero 40 / Semibold, only for rare full-page statements.
  static TextStyle get hero =>
      _style(size: 40, weight: 600, tracking: -1.4, height: 1.02);

  /// Display 30 / Bold for page titles.
  static TextStyle get display =>
      _style(size: 30, weight: 700, tracking: -1.0, height: 1.06);

  /// Title 21 / Semibold for section headers.
  static TextStyle get title =>
      _style(size: 21, weight: 600, tracking: -0.45, height: 1.15);

  /// Brand 19 / Semibold, natural tracking for the wordmark.
  static TextStyle get brand =>
      _style(size: 19, weight: 650, tracking: -0.25, height: 1.1);

  /// Subtitle 15.5 / Semibold for track and card titles.
  static TextStyle get subtitle =>
      _style(size: 15.5, weight: 600, tracking: -0.18, height: 1.3);

  /// Body 14.5 / Medium for reading and controls.
  static TextStyle get body =>
      _style(size: 14.5, weight: 500, tracking: -0.05, height: 1.42);

  /// Caption 12.5 / Regular for artist names and secondary metadata.
  static TextStyle get caption => _style(
    size: 12.5,
    weight: 400,
    tracking: 0,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  /// Overline 10.5 / Semibold, tracked out for eyebrows and labels.
  static TextStyle get overline => _style(
    size: 10.5,
    weight: 600,
    tracking: 1.6,
    height: 1.2,
    color: AppColors.textSecondary,
  );

  static TextStyle _style({
    required double size,
    required double weight,
    required double tracking,
    required double height,
    Color color = AppColors.textPrimary,
  }) => TextStyle(
    fontFamily: _family,
    fontSize: size.sp,
    fontWeight: _weight(weight),
    fontVariations: [FontVariation('wght', weight)],
    letterSpacing: tracking,
    height: height,
    color: color,
  );

  static FontWeight _weight(double weight) => switch (weight) {
    >= 800 => FontWeight.w800,
    >= 700 => FontWeight.w700,
    >= 600 => FontWeight.w600,
    >= 500 => FontWeight.w500,
    _ => FontWeight.w400,
  };
}
