import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/features/settings/domain/entities/app_settings.dart';
import 'package:aura_music/features/settings/domain/repositories/settings_repository.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';

final class _MockSettingsRepository extends Mock
    implements SettingsRepository {}

void main() {
  late _MockSettingsRepository repository;
  late DeviceTierService tiers;
  late SettingsCubit cubit;

  setUpAll(() {
    registerFallbackValue(const AppSettings.defaults());
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  setUp(() {
    repository = _MockSettingsRepository();
    tiers = DeviceTierService();
    cubit = SettingsCubit(repository, tiers);
    addTearDown(cubit.close);
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'load reads persisted settings and applies the glass override',
    () async {
      when(repository.load).thenAnswer(
        (_) async =>
            const AppSettings(glassOverride: 'low', dynamicColor: false),
      );

      await cubit.load();

      expect(cubit.state.settings.glassOverride, 'low');
      expect(cubit.state.glassTier, GlassTier.low);
      expect(tiers.tier.value, GlassTier.low);
    },
  );

  test('setGlassTier persists a named override', () async {
    when(() => repository.save(any())).thenAnswer((_) async {});

    await cubit.setGlassTier(GlassTier.mid);

    expect(cubit.state.glassTier, GlassTier.mid);
    final saved =
        verify(() => repository.save(captureAny())).captured.single
            as AppSettings;
    expect(saved.glassOverride, 'mid');
    expect(tiers.tier.value, GlassTier.mid);
  });

  test('setGlassTier(null) clears the override (Auto)', () async {
    when(() => repository.save(any())).thenAnswer((_) async {});

    await cubit.setGlassTier(null);

    expect(cubit.state.glassTier, isNull);
    final saved =
        verify(() => repository.save(captureAny())).captured.single
            as AppSettings;
    expect(saved.glassOverride, isNull);
  });

  test('toggles dynamic colour and AMOLED', () async {
    when(() => repository.save(any())).thenAnswer((_) async {});

    await cubit.setDynamicColor(false);
    await cubit.setAmoled(true);

    expect(cubit.state.settings.dynamicColor, isFalse);
    expect(cubit.state.settings.amoled, isTrue);
  });
}
