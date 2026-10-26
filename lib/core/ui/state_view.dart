import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/typography.dart';

/// Loading / empty / error / offline state view (PRD Section 14).

/// State kind.
enum StateKind {
  /// Loading (shows skeleton slot).
  loading,

  /// Empty result set.
  empty,

  /// Error with retry.
  error,

  /// Offline with retry.
  offline,
}

/// Renders one state with an optional retry action.
final class StateView extends StatelessWidget {
  /// Creates a state view.
  const StateView({
    super.key,
    required this.kind,
    required this.message,
    this.onRetry,
    this.loadingSlot,
  });

  /// Which state to render.
  final StateKind kind;

  /// User-facing message.
  final String message;

  /// Retry callback (error / offline only).
  final VoidCallback? onRetry;

  /// Custom loading widget (defaults to a spinner).
  final Widget? loadingSlot;

  @override
  Widget build(BuildContext context) {
    if (kind == StateKind.loading) {
      return Center(child: loadingSlot ?? const CircularProgressIndicator());
    }
    final icon = switch (kind) {
      StateKind.empty => Icons.inbox_outlined,
      StateKind.error => Icons.error_outline,
      StateKind.offline => Icons.wifi_off_outlined,
      StateKind.loading => Icons.hourglass_empty,
    };
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.r),
            SizedBox(height: 12.w),
            Text(
              message,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && kind != StateKind.empty) ...[
              SizedBox(height: 12.w),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
