import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/audio_cache_service.dart';
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
                      Divider(height: 32.w),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Audio normalization'),
                        subtitle: const Text(
                          'Balances track loudness to standard level (-14 LUFS) '
                          'to prevent sudden volume spikes.',
                        ),
                        value: settings.audioNormalization,
                        onChanged: cubit.setAudioNormalization,
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Equalizer',
                          style: AppTypography.subtitle.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'On-device 5-band hardware DSP tone controls.',
                        ),
                        value: settings.equalizerEnabled,
                        onChanged: cubit.setEqualizerEnabled,
                      ),
                      if (settings.equalizerEnabled) ...[
                        SizedBox(height: 12.w),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.w,
                          children: [
                            for (final (id, label) in _presets)
                              ChoiceChip(
                                label: Text(label),
                                selected: settings.equalizerPreset == id,
                                onSelected: (_) => cubit.setEqualizerPreset(id),
                              ),
                          ],
                        ),
                        SizedBox(height: 16.w),
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
                                  onChanged: (val) =>
                                      cubit.setEqualizerBandGain(i, val),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Smart audio disk cache',
                          style: AppTypography.subtitle.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically caches played songs to disk so repeating them uses zero internet and starts instantly.',
                        ),
                        value: settings.smartAudioCache,
                        onChanged: cubit.setSmartAudioCache,
                      ),
                      if (settings.smartAudioCache) ...[
                        Divider(height: 24.w),
                        const _AudioCacheManager(),
                      ],
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

  static double _nearest(double value) =>
      _speeds.reduce((a, b) => (a - value).abs() <= (b - value).abs() ? a : b);
}

final class _AudioCacheManager extends StatefulWidget {
  const _AudioCacheManager();

  @override
  State<_AudioCacheManager> createState() => _AudioCacheManagerState();
}

final class _AudioCacheManagerState extends State<_AudioCacheManager> {
  int _cacheBytes = 0;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  Future<void> _refreshSize() async {
    if (getIt.isRegistered<AudioCacheService>()) {
      final size = await getIt<AudioCacheService>().getCacheSizeBytes();
      if (mounted) setState(() => _cacheBytes = size);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _clearing = true);
    if (getIt.isRegistered<AudioCacheService>()) {
      await getIt<AudioCacheService>().clearCache();
    }
    if (mounted) {
      setState(() {
        _cacheBytes = 0;
        _clearing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio cache cleared successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mb = (_cacheBytes / (1024 * 1024)).toStringAsFixed(1);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disk usage',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.w),
              Text(
                '$mb MB cached (Max 512 MB)',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _clearing || _cacheBytes == 0 ? null : _clearCache,
          icon: _clearing
              ? SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.delete_outline_rounded, size: 18.r),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}
