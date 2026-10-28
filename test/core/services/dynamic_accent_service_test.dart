import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/dynamic_accent_service.dart';

void main() {
  group('DynamicAccentService.clampAccent', () {
    test('raises an over-saturated dark colour into the readable window', () {
      final clamped = DynamicAccentService.clampAccent(
        HSLColor.fromAHSL(1, 200, 0.95, 0.25).toColor(),
      );
      final hsl = HSLColor.fromColor(clamped);
      expect(hsl.saturation, closeTo(0.52, 0.005));
      expect(hsl.lightness, closeTo(0.62, 0.005));
      expect(hsl.hue, closeTo(200, 0.5));
    });

    test('lowers a washed-out bright colour into the readable window', () {
      final clamped = DynamicAccentService.clampAccent(
        HSLColor.fromAHSL(1, 40, 0.20, 0.92).toColor(),
      );
      final hsl = HSLColor.fromColor(clamped);
      expect(hsl.saturation, closeTo(0.30, 0.005));
      expect(hsl.lightness, closeTo(0.75, 0.005));
    });

    test('keeps an already in-range accent untouched', () {
      final source = HSLColor.fromAHSL(1, 250, 0.42, 0.68).toColor();
      final clamped = DynamicAccentService.clampAccent(source);
      final hsl = HSLColor.fromColor(clamped);
      expect(hsl.saturation, closeTo(0.42, 0.005));
      expect(hsl.lightness, closeTo(0.68, 0.005));
    });
  });
}
