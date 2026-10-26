import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';

/// Inter type scale (PRD 8.2).
abstract final class AppTypography {
  static const String _family = 'Inter';

  /// Display 28 / ExtraBold for brand header.
  static TextStyle get display => TextStyle(
    fontFamily: _family,
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  /// Title 19 / Bold for section headers.
  static TextStyle get title => TextStyle(
    fontFamily: _family,
    fontSize: 19.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  /// Subtitle 14.5 / SemiBold for track/card titles.
  static TextStyle get subtitle => TextStyle(
    fontFamily: _family,
    fontSize: 14.5.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  /// Body 14 / Medium.
  static TextStyle get body => TextStyle(
    fontFamily: _family,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// Caption 12 / Regular for artist names & secondary metadata.
  static TextStyle get caption => TextStyle(
    fontFamily: _family,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  /// Overline 10.5 / SemiBold, tracked out.
  static TextStyle get overline => TextStyle(
    fontFamily: _family,
    fontSize: 10.5.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.2,
    color: AppColors.textSecondary,
  );
}
