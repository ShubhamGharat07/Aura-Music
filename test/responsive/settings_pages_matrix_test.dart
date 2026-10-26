import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/features/settings/domain/repositories/settings_repository.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/pages/audio_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/updates_settings_page.dart';

import '../helpers/pump_app.dart';
import '../helpers/window_sizes.dart';

final class _MockSettingsRepository extends Mock
    implements SettingsRepository {}

/// Settings surfaces must stay overflow-free across the PRD 12.1 matrix
/// (small phone through large tablet, both orientations).
void main() {
  late SettingsCubit cubit;

  setUp(() {
    cubit = SettingsCubit(_MockSettingsRepository(), DeviceTierService());
    addTearDown(cubit.close);
  });

  for (final size in kWindowSizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    final base = switch (WindowSizeClass.ofWidth(size.shortestSide)) {
      WindowSizeClass.compact => const Size(393, 852),
      WindowSizeClass.medium => const Size(744, 1133),
      _ => const Size(1194, 834),
    };
    final design = size.width > size.height
        ? Size(base.height, base.width)
        : base;

    testWidgets('settings root fits at $label', (tester) async {
      await _pump(tester, cubit, const SettingsPage(), size, design);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Audio & EQ'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('audio settings fit at $label', (tester) async {
      await _pump(tester, cubit, const AudioSettingsPage(), size, design);
      expect(find.text('Playback speed'), findsOneWidget);
      expect(find.text('Skip silence'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('updates settings fit at $label', (tester) async {
      await _pump(tester, cubit, const UpdatesSettingsPage(), size, design);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  SettingsCubit cubit,
  Widget page,
  Size size,
  Size design,
) async {
  await pumpApp(
    tester,
    BlocProvider<SettingsCubit>.value(value: cubit, child: page),
    size: size,
    designSize: design,
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}
