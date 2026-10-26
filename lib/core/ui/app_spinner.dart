import 'package:flutter/material.dart';

/// Compact, brand-tinted loading spinner (PRD Section 14). A rounded-arc
/// [CircularProgressIndicator] sized for inline use in sections and lists.

/// Inline loading spinner.
final class AppSpinner extends StatelessWidget {
  /// Creates a spinner.
  const AppSpinner({super.key, this.size = 28, this.strokeWidth = 3});

  /// Diameter in logical pixels.
  final double size;

  /// Arc thickness.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}
