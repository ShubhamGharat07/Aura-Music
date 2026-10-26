import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings.copyWith', () {
    test('returns defaults', () {
      const settings = AppSettings.defaults();
      expect(settings.glassOverride, isNull);
      expect(settings.dynamicColor, isTrue);
      expect(settings.amoled, isFalse);
    });

    test('overrides individual fields', () {
      final next = const AppSettings().copyWith(
        amoled: true,
        dynamicColor: false,
      );
      expect(next.amoled, isTrue);
      expect(next.dynamicColor, isFalse);
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
