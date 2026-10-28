import 'package:flutter/material.dart';

import 'package:aura_music/core/theme/colors.dart';

// Full-screen player backdrop. A single accent wash falls from the top, then
// dissolves into the page colour, so the artwork still owns the colour without
// the page looking like a flat sheet.

/// Player background with one restrained accent wash.
final class PlayerBackground extends StatelessWidget {
  /// Creates the background.
  const PlayerBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.42, 1],
          colors: [
            accent.withValues(alpha: 0.13),
            AppColors.bg.withValues(alpha: 0),
            AppColors.bg.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
