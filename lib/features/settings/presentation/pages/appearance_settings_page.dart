import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';

/// Appearance settings (PRD S16): glass tier, dynamic colour, AMOLED.

/// Appearance sub-page.
final class AppearanceSettingsPage extends StatelessWidget {
  /// Creates the appearance page.
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: MaxContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            pad,
            pad,
            pad + MediaQuery.paddingOf(context).bottom,
          ),
          children: const [_AppearanceCard()],
        ),
      ),
    );
  }
}

final class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        return GlassSurface.fake(
          borderRadius: AppRadius.card,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Glass effect',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.w),
              Text('Blur intensity; Auto matches your device tier.'),
              SizedBox(height: 12.w),
              SegmentedButton<GlassTier?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: null, label: Text('Auto')),
                  ButtonSegment(value: GlassTier.high, label: Text('High')),
                  ButtonSegment(value: GlassTier.mid, label: Text('Mid')),
                  ButtonSegment(value: GlassTier.low, label: Text('Low')),
                ],
                selected: {state.glassTier},
                onSelectionChanged: (s) =>
                    context.read<SettingsCubit>().setGlassTier(s.first),
              ),
              Divider(height: 32.w),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dynamic colour'),
                subtitle: const Text('Tint accents from the artwork'),
                value: settings.dynamicColor,
                onChanged: context.read<SettingsCubit>().setDynamicColor,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AMOLED black'),
                subtitle: const Text('True-black base for OLED screens'),
                value: settings.amoled,
                onChanged: (v) {
                  context.read<SettingsCubit>().setAmoled(v);
                  context.read<ThemeCubit>().setAmoled(v);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
