import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/router/app_dialog.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_sheet.dart';
import 'package:aura_music/core/utils/formatters.dart';
import 'package:aura_music/features/player/data/services/sleep_timer_service.dart';
import 'package:aura_music/features/player/domain/entities/sleep_timer.dart';

/// Sleep timer overlay (PRD O3 / F17): presets, countdown and end-of-track.

/// Opens the sleep timer sheet.
Future<void> showSleepTimerSheet(BuildContext context) {
  final service = getIt<SleepTimerService>();
  return GlassSheet.show<void>(
    context,
    (sheetContext) => _SleepTimerSheet(service: service),
  );
}

final class _SleepTimerSheet extends StatelessWidget {
  const _SleepTimerSheet({required this.service});

  static const _presets = <(String, Duration)>[
    ('5 min', Duration(minutes: 5)),
    ('10 min', Duration(minutes: 10)),
    ('15 min', Duration(minutes: 15)),
    ('30 min', Duration(minutes: 30)),
    ('45 min', Duration(minutes: 45)),
    ('60 min', Duration(minutes: 60)),
  ];

  final SleepTimerService service;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<SleepTimerState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: service.remaining,
          builder: (context, remaining, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_rounded, color: accent, size: 22.r),
                    SizedBox(width: AppSpacing.sm),
                    Text('Sleep timer', style: AppTypography.title),
                    const Spacer(),
                    if (state.isActive)
                      Text(
                        state.endOfTrack
                            ? 'End of track'
                            : formatDuration(remaining),
                        style: AppTypography.subtitle.copyWith(color: accent),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                Text(_caption(state), style: AppTypography.caption),
                SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Off'),
                      selected: !state.isActive,
                      onSelected: (_) {
                        service.cancel();
                        closeOverlay(context);
                      },
                    ),
                    for (final preset in _presets)
                      ChoiceChip(
                        label: Text(preset.$1),
                        selected: state.total == preset.$2,
                        onSelected: (_) {
                          service.start(preset.$2);
                          closeOverlay(context);
                        },
                      ),
                    ChoiceChip(
                      label: const Text('End of track'),
                      selected: state.endOfTrack,
                      onSelected: (_) {
                        service.startEndOfTrack();
                        closeOverlay(context);
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'The timer keeps running while Aura is in the background.',
                  style: AppTypography.caption,
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            );
          },
        );
      },
    );
  }

  String _caption(SleepTimerState state) {
    if (state.endOfTrack) return 'Playback pauses when this track ends.';
    if (!state.isActive) return 'Pause playback after a set time.';
    final total = state.total;
    if (total == null) return 'Playback will pause automatically.';
    return 'Pausing in ${_labels[total] ?? formatDuration(total)}.';
  }

  static final Map<Duration, String> _labels = {
    for (final preset in _presets) preset.$2: preset.$1,
  };
}
