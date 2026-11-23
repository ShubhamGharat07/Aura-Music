import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/hooks/use_playback_motion.dart';

/// Small equalizer that pulses while a track is playing.
///
/// Painted by a [CustomPainter] driven by the animation controller, so the
/// surrounding widgets are not rebuilt on every frame.
final class PlayingBars extends HookWidget {
  /// Creates the equalizer.
  const PlayingBars({
    super.key,
    required this.color,
    this.size = 14,
    this.playing = true,
  });

  /// Bar colour.
  final Color color;

  /// Square edge length.
  final double size;

  /// Whether the bars animate (false = parked at rest).
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final animate = usePlaybackMotion(context, playing: playing);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      if (animate) {
        controller.repeat();
      } else {
        controller.stop();
        controller.value = 0;
      }
      return null;
    }, [controller, animate]);

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _BarsPainter(
          color: color,
          progress: controller,
          animate: animate,
        ),
      ),
    );
  }
}

final class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.color,
    required this.progress,
    required this.animate,
  }) : super(repaint: progress);

  final Color color;
  final Animation<double> progress;
  final bool animate;

  static const int _bars = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final width = size.width * 0.14;
    final gap = (size.width - width * _bars) / (_bars - 1);
    for (var i = 0; i < _bars; i++) {
      final phase = (progress.value + i * 0.22) % 1;
      final wave = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
      final level = animate ? 0.35 + 0.65 * wave : 0.4 + 0.1 * i;
      final height = size.height * level;
      final x = i * (width + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, width, height),
        Radius.circular(width),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.animate != animate;
}
