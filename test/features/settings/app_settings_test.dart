import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings.copyWith', () {
    test('returns defaults', () {
      const settings = AppSettings.defaults();
      expect(settings.glassOverride, isNull);
      expect(settings.dynamicColor, isTrue);
      expect(settings.amoled, isFalse);
      expect(settings.audioNormalization, isTrue);
      expect(settings.equalizerEnabled, isTrue);
      expect(settings.equalizerPreset, 'flat');
      expect(settings.equalizerBands, const [0.0, 0.0, 0.0, 0.0, 0.0]);
      expect(settings.smartAudioCache, isTrue);
      expect(settings.maxCacheSizeMb, 512);
    });

    test('overrides individual fields', () {
      final next = const AppSettings().copyWith(
        amoled: true,
        dynamicColor: false,
        audioNormalization: false,
        equalizerEnabled: false,
        equalizerPreset: 'bass_boost',
        equalizerBands: const [6.0, 4.0, 0.0, 0.0, -1.0],
        smartAudioCache: false,
        maxCacheSizeMb: 1024,
      );
      expect(next.amoled, isTrue);
      expect(next.dynamicColor, isFalse);
      expect(next.audioNormalization, isFalse);
      expect(next.equalizerEnabled, isFalse);
      expect(next.equalizerPreset, 'bass_boost');
      expect(next.equalizerBands, const [6.0, 4.0, 0.0, 0.0, -1.0]);
      expect(next.smartAudioCache, isFalse);
      expect(next.maxCacheSizeMb, 1024);
    });

    test('clearGlass drops the override regardless of value', () {
      final next = const AppSettings(
        glassOverride: 'high',
      ).copyWith(glassOverride: 'mid', clearGlass: true);
      expect(next.glassOverride, isNull);
    });

    test('setting a glass override keeps the others', () {
      final next = const AppSettings(
        amoled: true,
      ).copyWith(glassOverride: 'low');
      expect(next.glassOverride, 'low');
      expect(next.amoled, isTrue);
    });
  });

  test('value equality holds for identical settings', () {
    expect(
      const AppSettings(glassOverride: 'low'),
      const AppSettings(glassOverride: 'low'),
    );
    expect(
      const AppSettings(glassOverride: 'low'),
      isNot(const AppSettings(glassOverride: 'high')),
    );
  });
}
