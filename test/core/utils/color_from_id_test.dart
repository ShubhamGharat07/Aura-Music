import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/color_from_id.dart';

void main() {
  group('accentFromId', () {
    test('is deterministic for the same id', () {
      expect(accentFromId('audius:123'), accentFromId('audius:123'));
    });

    test('yields different colours for different ids', () {
      expect(accentFromId('track-a'), isNot(accentFromId('track-b')));
    });

    test('honours custom saturation and lightness', () {
      final bright = accentFromId('x', saturation: 0.9, lightness: 0.8);
      final muted = accentFromId('x', saturation: 0.2, lightness: 0.4);
      expect(bright, isNot(muted));
    });
  });
}
