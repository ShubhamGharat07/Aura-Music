import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/utils/formatters.dart';

/// Seek bar (PRD 4.1 + 8.3). Reads position from a [ValueListenable]
/// (>=10 Hz) so the whole player does not rebuild. Dragging is ephemeral
/// UI state handled by hooks, never `setState`.
///
/// The track is a single [CustomPaint] driven by the position notifier and a
/// drag notifier, so playback progress repaints two small layers instead of
/// rebuilding a Material [Slider] (and its theme, layout and ink state) every
/// tick. Buffered progress, which the old slider silently dropped, is painted
/// between the inactive and active tracks.
final class SeekBar extends HookWidget {
  /// Creates a seek bar.
  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffered,
    this.onSeek,
    this.showLabels = true,
    this.accent,
  });

  /// Playback position notifier (owned by the player service/BLoC).
  final ValueListenable<Duration> position;

  /// Track total duration.
  final Duration duration;

  /// Optional buffered-position notifier.
  final ValueListenable<Duration>? buffered;

  /// Called with the final position when the user releases the thumb.
  final ValueChanged<Duration>? onSeek;

  /// Shows the elapsed / total labels.
  final bool showLabels;

  /// Accent colour (defaults to the theme primary).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final totalMs = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;
    final drag = useMemoized(() => ValueNotifier<double?>(null));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeekTrack(
          position: position,
          buffered: buffered,
          duration: duration,
          accent: color,
          drag: drag,
          totalMs: totalMs,
          onSeek: onSeek,
        ),
        if (showLabels)
          _SeekLabels(
            position: position,
            duration: duration,
            drag: drag,
            totalMs: totalMs,
          ),
      ],
    );
  }
}

/// Interactive track + thumb. The drag value is shared with the labels so the
/// elapsed time follows the finger without rebuilding the track subtree.
final class _SeekTrack extends HookWidget {
  const _SeekTrack({
    required this.position,
    required this.buffered,
    required this.duration,
    required this.accent,
    required this.drag,
    required this.totalMs,
    this.onSeek,
  });

  final ValueListenable<Duration> position;
  final ValueListenable<Duration>? buffered;
  final Duration duration;
  final Color accent;
  final ValueNotifier<double?> drag;
  final int totalMs;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final repaint = useMemoized(
      () => Listenable.merge([position, ?buffered, drag]),
      [position, buffered, drag],
    );

    void commit(double ratio) {
      drag.value = null;
      onSeek?.call(Duration(milliseconds: (ratio * totalMs).round()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const thumbRadius = 7.0;
        final width = constraints.maxWidth;
        final trackWidth = width - thumbRadius * 2;
        double ratioOf(Offset local) => trackWidth <= 0
            ? 0
            : ((local.dx - thumbRadius) / trackWidth).clamp(0.0, 1.0);
        Duration clamp(Duration value) => value < Duration.zero
            ? Duration.zero
            : (value > duration ? duration : value);
        void nudge(Duration delta) =>
            onSeek?.call(clamp(position.value + delta));
        final value = position.value;

        return Semantics(
          slider: true,
          label: 'Playback position',
          value: formatDuration(value),
          increasedValue: formatDuration(
            clamp(value + const Duration(seconds: 10)),
          ),
          decreasedValue: formatDuration(
            clamp(value - const Duration(seconds: 10)),
          ),
          onIncrease: () => nudge(const Duration(seconds: 10)),
          onDecrease: () => nudge(const Duration(seconds: -10)),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => drag.value = ratioOf(details.localPosition),
            onTapUp: (details) => commit(ratioOf(details.localPosition)),
            onTapCancel: () => drag.value = null,
            onHorizontalDragStart: (details) =>
                drag.value = ratioOf(details.localPosition),
            onHorizontalDragUpdate: (details) =>
                drag.value = ratioOf(details.localPosition),
            onHorizontalDragEnd: (_) {
              final value = drag.value;
              if (value != null) commit(value);
            },
            onHorizontalDragCancel: () => drag.value = null,
            child: SizedBox(
              height: 30,
              child: CustomPaint(
                painter: _SeekPainter(
                  position: position,
                  buffered: buffered,
                  duration: duration,
                  accent: accent,
                  drag: drag,
                  repaint: repaint,
                ),
                size: Size(width, 30),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _SeekPainter extends CustomPainter {
  const _SeekPainter({
    required this.position,
    required this.buffered,
    required this.duration,
    required this.accent,
    required this.drag,
    required this.repaint,
  }) : super(repaint: repaint);

  final ValueListenable<Duration> position;
  final ValueListenable<Duration>? buffered;
  final Duration duration;
  final Color accent;
  final ValueNotifier<double?> drag;
  final Listenable repaint;

  @override
  void paint(Canvas canvas, Size size) {
    const trackHeight = 3.0;
    const thumbRadius = 7.0;
    final totalMs = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;
    final dragged = drag.value;
    final progress = (dragged ?? position.value.inMilliseconds / totalMs).clamp(
      0.0,
      1.0,
    );
    final bufferedProgress = buffered == null
        ? progress
        : (buffered!.value.inMilliseconds / totalMs).clamp(progress, 1.0);
    final left = thumbRadius;
    final right = size.width - thumbRadius;
    final trackWidth = (right - left).clamp(0.0, double.infinity);
    final cy = size.height / 2;
    final centerX = left + trackWidth * progress;

    final background = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final bufferedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    final active = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final trackRect = Rect.fromLTWH(
      left,
      cy - trackHeight / 2,
      trackWidth,
      trackHeight,
    );
    final track = RRect.fromRectAndRadius(trackRect, const Radius.circular(2));
    canvas.drawRRect(track, background);
    if (bufferedProgress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            cy - trackHeight / 2,
            trackWidth * bufferedProgress,
            trackHeight,
          ),
          const Radius.circular(2),
        ),
        bufferedPaint,
      );
    }
    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            cy - trackHeight / 2,
            trackWidth * progress,
            trackHeight,
          ),
          const Radius.circular(2),
        ),
        active,
      );
    }

    final dragging = drag.value != null;
    final glow = Paint()
      ..color = accent.withValues(alpha: dragging ? 0.24 : 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, cy), dragging ? 15 : 12, glow);
    canvas.drawCircle(Offset(centerX, cy), thumbRadius + 1.4, active);
    canvas.drawCircle(
      Offset(centerX, cy),
      thumbRadius - 2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  @override
  bool shouldRepaint(_SeekPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.duration != duration ||
      oldDelegate.position != position ||
      oldDelegate.buffered != buffered ||
      oldDelegate.drag != drag;
}

/// Elapsed / total labels. Listens to the same drag notifier as the track so
/// dragging updates the time without rebuilding the player layout.
final class _SeekLabels extends HookWidget {
  const _SeekLabels({
    required this.position,
    required this.duration,
    required this.drag,
    required this.totalMs,
  });

  final ValueListenable<Duration> position;
  final Duration duration;
  final ValueNotifier<double?> drag;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    final animation = useMemoized(() => Listenable.merge([position, drag]), [
      position,
      drag,
    ]);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final dragged = drag.value;
        final current = dragged == null
            ? position.value
            : Duration(milliseconds: (dragged * totalMs).round());
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(current), style: style),
            Text(formatDuration(duration), style: style),
          ],
        );
      },
    );
  }
}
