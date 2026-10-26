import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Configures ScreenUtil for the current logical window.
///
/// `ScreenUtilInit` walks the element tree and marks every custom descendant
/// dirty whenever the size changes. On rotation that forced the whole app
/// (all four preloaded branches) to rebuild, which is the multi-second freeze
/// this replaces. Here the host supplies a fresh design size and normal Flutter
/// dependency/constraint invalidation handles the subtree instead.
final class ScreenScale extends StatelessWidget {
  /// Creates a scale context for [child].
  const ScreenScale({super.key, required this.designSize, required this.child});

  /// Design draft for the current window (orientation-aware).
  final Size designSize;

  /// App subtree sized with ScreenUtil tokens.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.configure(
      data: MediaQuery.of(context),
      designSize: designSize,
      splitScreenMode: true,
      minTextAdapt: true,
    );
    return child;
  }
}
