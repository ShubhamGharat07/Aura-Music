import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_sheet.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';

/// Equalizer bottom sheet overlay (Vivi / Spotify style quick audio tuner).
/// Opens directly from Now Playing 3-dots menu.

/// Shows the equalizer bottom sheet.
Future<void> showEqualizerSheet(BuildContext context) {
  final cubit = getIt<SettingsCubit>();
  return GlassSheet.show<void>(
    context,
    (sheetContext) => BlocProvider<SettingsCubit>.value(
      value: cubit,
      child: const _EqualizerSheet(),
    ),
  );
}

final class _EqualizerSheet extends StatelessWidget {
  const _EqualizerSheet();

  static const List<String> _bandLabels = <String>[
    '60 Hz',
    '230 Hz',
    '910 Hz',
    '3.6 kHz',
    '14 kHz',
  ];

  static const List<(String, String)> _presets = <(String, String)>[
    ('flat', 'Flat'),
    ('bass_boost', 'Bass Boost'),
    ('vocal_boost', 'Vocal Boost'),
    ('rock', 'Rock'),
    ('electronic', 'Electronic'),
    ('custom', 'Custom'),
  ];

  static String _formatDb(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${value.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        final cubit = context.read<SettingsCubit>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.equalizer_rounded, color: accent, size: 22.r),
                SizedBox(width: AppSpacing.sm),
                Text('Equalizer', style: AppTypography.title),
                const Spacer(),
                Switch(
                  value: settings.equalizerEnabled,
                  onChanged: cubit.setEqualizerEnabled,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              settings.equalizerEnabled
                  ? '5-band hardware DSP tone controls'
                  : 'Equalizer is turned off',
              style: AppTypography.caption,
            ),
            if (settings.equalizerEnabled) ...[
              SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (id, label) in _presets)
                    ChoiceChip(
                      label: Text(label),
                      selected: settings.equalizerPreset == id,
                      onSelected: (_) => cubit.setEqualizerPreset(id),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < _bandLabels.length; i++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 56.w,
                      child: Text(
                        _bandLabels[i],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: (i < settings.equalizerBands.length
                                ? settings.equalizerBands[i]
                                : 0.0)
                            .clamp(-12.0, 12.0),
                        min: -12.0,
                        max: 12.0,
                        divisions: 24,
                        onChanged: (val) => cubit.setEqualizerBandGain(i, val),
                      ),
                    ),
                    SizedBox(
                      width: 52.w,
                      child: Text(
                        _formatDb(
                          i < settings.equalizerBands.length
                              ? settings.equalizerBands[i]
                              : 0.0,
                        ),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            Divider(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18.r,
                  color: settings.audioNormalization
                      ? accent
                      : Theme.of(context).colorScheme.outline,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio normalization',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Equal loudness across tracks (-14 LUFS)',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.audioNormalization,
                  onChanged: cubit.setAudioNormalization,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
