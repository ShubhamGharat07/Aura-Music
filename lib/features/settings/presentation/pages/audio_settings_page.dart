import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Audio & EQ settings (PRD S18): playback speed and skip-silence are wired to
/// the shared controller; the equalizer section states the DSP roadmap instead
/// of showing controls that would not do anything yet.

/// Audio sub-page.
final class AudioSettingsPage extends StatelessWidget {
  /// Creates the audio page.
  const AudioSettingsPage({super.key});

  static const List<double> _speeds = <double>[0.75, 1.0, 1.25, 1.5];

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).audioTitle)),
      body: MaxContentWidth(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final settings = state.settings;
            final cubit = context.read<SettingsCubit>();
            return ListView(
              padding: EdgeInsets.fromLTRB(
                pad,
                pad,
                pad,
                pad + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                GlassSurface.fake(
                  borderRadius: AppRadius.card,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Playback speed',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.w),
                      const Text('Applies instantly and survives restarts.'),
                      SizedBox(height: 12.w),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.w,
                        children: [
                          for (final speed in _speeds)
                            ChoiceChip(
                              label: Text('${speed}x'),
                              selected:
                                  _nearest(settings.playbackSpeed) == speed,
                              onSelected: (_) => cubit.setPlaybackSpeed(speed),
                            ),
                        ],
                      ),
                      Divider(height: 32.w),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Skip silence'),
                        subtitle: const Text(
                          'Jumps over silent intros and gaps while '
                          'playing (speech, live sets).',
                        ),
                        value: settings.skipSilence,
                        onChanged: cubit.setSkipSilence,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.w),
                GlassSurface.fake(
                  borderRadius: AppRadius.card,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equalizer',
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6.w),
                      const Text(
                        'The five-band EQ ships with the on-device DSP engine. '
                        'Until then speed and skip-silence are the available '
                        'audio controls.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _nearest(double value) =>
      _speeds.reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);
}
