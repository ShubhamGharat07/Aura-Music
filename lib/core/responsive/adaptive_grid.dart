import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Column-count helper for grids (PRD 7.2). Album art, grids and panels
/// use constraints + this helper, never raw `.w`, so tablets do not balloon.

/// Computes a column count from available width and a target card width.
///
/// Example: media card 150 dp -> 2 cols @360, 4 @700, 6 @1000.
abstract final class AdaptiveGrid {
  /// Returns at least [minColumns] columns that fit in [availableWidth].
  static int columns({
    required double availableWidth,
    required double targetCardWidth,
    int minColumns = 2,
    int? maxColumns,
  }) {
    assert(targetCardWidth > 0, 'targetCardWidth must be positive');
    var count = (availableWidth / targetCardWidth).floor();
    if (count < minColumns) count = minColumns;
    if (maxColumns != null && count > maxColumns) count = maxColumns;
    return count;
  }

  /// Sliver delegate for a fixed card width with 12 dp gaps.
  static SliverGridDelegateWithFixedCrossAxisCount delegate({
    required double availableWidth,
    required double targetCardWidth,
  }) {
    final count = columns(
      availableWidth: availableWidth,
      targetCardWidth: targetCardWidth,
    );
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      mainAxisSpacing: 12.w,
      crossAxisSpacing: 12.w,
      childAspectRatio: 0.72,
    );
  }
}
