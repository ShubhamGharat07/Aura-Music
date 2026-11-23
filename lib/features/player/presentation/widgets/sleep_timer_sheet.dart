import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/router/app_dialog.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_button.dart';
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

final class _SleepTimerSheet extends StatefulWidget {
  const _SleepTimerSheet({required this.service});

  final SleepTimerService service;

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  late double _customMinutes;

  static const _presets = <(String, Duration)>[
    ('5 min', Duration(minutes: 5)),
    ('10 min', Duration(minutes: 10)),
    ('15 min', Duration(minutes: 15)),
    ('30 min', Duration(minutes: 30)),
    ('45 min', Duration(minutes: 45)),
    ('60 min', Duration(minutes: 60)),
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.service.state.value.total?.inMinutes.toDouble();
    _customMinutes = (current != null && current >= 1.0 && current <= 180.0)
        ? current
        : 30.0;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ValueListenableBuilder<SleepTimerState>(
      valueListenable: widget.service.state,
      builder: (context, state, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: widget.service.remaining,
          builder: (context, remaining, _) {
            final activeTotal = state.total?.inMinutes;
            final isCustomActive = state.isActive &&
                !state.endOfTrack &&
                !_presets.any((p) => p.$2 == state.total);

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
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Off'),
                      selected: !state.isActive,
                      onSelected: (_) {
                        widget.service.cancel();
                        closeOverlay(context);
                      },
                    ),
                    for (final preset in _presets)
                      ChoiceChip(
                        label: Text(preset.$1),
                        selected: state.total == preset.$2,
                        onSelected: (_) {
                          setState(
                            () => _customMinutes =
                                preset.$2.inMinutes.toDouble(),
                          );
                          widget.service.start(preset.$2);
                          closeOverlay(context);
                        },
                      ),
                    ChoiceChip(
                      label: const Text('End of track'),
                      selected: state.endOfTrack,
                      onSelected: (_) {
                        widget.service.startEndOfTrack();
                        closeOverlay(context);
                      },
                    ),
                  ],
                ),
                Divider(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom duration',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.w,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _formatMinutes(_customMinutes.round()),
                        style: TextStyle(
                          color: accent,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      '1m',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _customMinutes.clamp(1.0, 180.0),
                        min: 1.0,
                        max: 180.0,
                        divisions: 179,
                        onChanged: (val) {
                          setState(() => _customMinutes = val);
                        },
                      ),
                    ),
                    Text(
                      '3h',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                GlassButton(
                  label: isCustomActive && activeTotal == _customMinutes.round()
                      ? 'Cancel timer'
                      : 'Set ${_formatMinutes(_customMinutes.round())} timer',
                  icon: isCustomActive && activeTotal == _customMinutes.round()
                      ? Icons.close_rounded
                      : Icons.timer_outlined,
                  expand: true,
                  onPressed: () {
                    if (isCustomActive &&
                        activeTotal == _customMinutes.round()) {
                      widget.service.cancel();
                    } else {
                      widget.service.start(
                        Duration(minutes: _customMinutes.round()),
                      );
                    }
                    closeOverlay(context);
                  },
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'The timer keeps running while Aura is in the background.',
                  style: AppTypography.caption,
                ),
                SizedBox(height: AppSpacing.xs),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  String _caption(SleepTimerState state) {
    if (state.endOfTrack) return 'Playback pauses when this track ends.';
    if (!state.isActive) return 'Pause playback after a set time.';
    final total = state.total;
    if (total == null) return 'Playback will pause automatically.';
    final presetLabel = _labels[total];
    if (presetLabel != null) return 'Pausing in $presetLabel.';
    return 'Pausing in ${_formatMinutes(total.inMinutes)}.';
  }

  static final Map<Duration, String> _labels = {
    for (final preset in _presets) preset.$2: preset.$1,
  };
}
