import 'package:flutter/widgets.dart';

import 'package:aura_music/core/responsive/window_size_class.dart';

/// Slot-based adaptive builder (PRD 7.2). Falls back to the nearest
/// smaller slot so callers only implement the slots they need.

/// Builds the nearest available slot at or below the current class.
final class AdaptiveLayout extends StatelessWidget {
  /// Creates an adaptive layout. At least [compact] is required.
  const AdaptiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
  });

  /// Compact slot (required).
  final WidgetBuilder compact;

  /// Medium slot (falls back to [compact]).
  final WidgetBuilder? medium;

  /// Expanded slot (falls back to [medium] then [compact]).
  final WidgetBuilder? expanded;

  /// Large slot (falls back down the chain).
  final WidgetBuilder? large;

  @override
  Widget build(BuildContext context) {
    final c = WindowSizeClass.of(context);
    final builder = switch (c) {
      WindowSizeClass.large => large ?? expanded ?? medium ?? compact,
      WindowSizeClass.expanded => expanded ?? medium ?? compact,
      WindowSizeClass.medium => medium ?? compact,
      WindowSizeClass.compact => compact,
    };
    return builder(context);
  }
}
