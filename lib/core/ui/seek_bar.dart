import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/utils/formatters.dart';

/// Seek bar (PRD 4.1 + 8.3). Reads position from a [ValueListenable]
/// (>=10 Hz) so the whole player does not rebuild. Dragging is ephemeral
/// UI state handled by hooks, never `setState`.
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
    final dragging = useState(false);
    final dragValue = useState(0.0);
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final totalMs = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;

    return ValueListenableBuilder<Duration>(
      valueListenable: position,
      builder: (context, pos, _) {
        final current = dragging.value
            ? dragValue.value
            : pos.inMilliseconds / totalMs;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: color,
                inactiveTrackColor: Colors.white24,
                secondaryActiveTrackColor: Colors.white38,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: current.clamp(0.0, 1.0),
                onChangeStart: (_) => dragging.value = true,
                onChanged: (v) => dragValue.value = v,
                onChangeEnd: (v) {
                  dragging.value = false;
                  onSeek?.call(Duration(milliseconds: (v * totalMs).round()));
                },
              ),
            ),
            if (showLabels)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(
                      dragging.value
                          ? Duration(
                              milliseconds: (dragValue.value * totalMs).round(),
                            )
                          : pos,
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    formatDuration(duration),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
