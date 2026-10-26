import 'package:flutter/material.dart';

import 'package:aura_music/core/services/device_tier_service.dart';

// Full-screen player backdrop: layered radial "blobs" over the base
// background, tinted with the track accent + a dark scrim so foreground
// contrast stays >= 4.5:1 (PRD 8.1 / 8.6). A blurred live bitmap is the
// Phase-1 upgrade; this gradient version is cheap and looks premium.

/// Animated-free (reduced-motion friendly) player background.
final class PlayerBackground extends StatelessWidget {
  /// Creates the background.
  const PlayerBackground({
    super.key,
    required this.accent,
    this.animated = true,
    this.tier = GlassTier.high,
  });

  /// Track accent colour.
  final Color accent;

  /// Enables the slow blob drift (disabled by reduce-motion).
  final bool animated;

  /// Device tier (low tier keeps it static and simplest).
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        _blob(accent, const Alignment(-0.9, -0.9), 0.9),
        _blob(accent.withValues(alpha: 0.55), const Alignment(1.0, -0.4), 0.75),
        _blob(accent.withValues(alpha: 0.4), const Alignment(-0.3, 1.1), 0.85),
        // Scrim keeps text legible over the glow.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, base.withValues(alpha: 0.5), base],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob(Color color, Alignment alignment, double scale) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: scale,
        heightFactor: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.55),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
