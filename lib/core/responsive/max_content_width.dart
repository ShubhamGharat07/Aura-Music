import 'package:flutter/widgets.dart';

import 'package:aura_music/core/theme/tokens.dart';

/// Centers content and clamps its width on Expanded/Large (PRD 7.2).

/// Clamps [child] to [maxWidth] and centers it.
final class MaxContentWidth extends StatelessWidget {
  /// Creates a max-width clamp. Use [AppLayout.maxReadingWidth] for text.
  const MaxContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
  });

  /// Content.
  final Widget child;

  /// Maximum width.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
