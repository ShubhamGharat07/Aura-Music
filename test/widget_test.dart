import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';

void main() {
  group('WindowSizeClass', () {
    test('maps widths to classes (PRD 7.1)', () {
      expect(WindowSizeClass.ofWidth(360), WindowSizeClass.compact);
      expect(WindowSizeClass.ofWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.ofWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.ofWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.ofWidth(1600), WindowSizeClass.large);
    });

    test('columns scale with width (media card 150 dp)', () {
      expect(
        AdaptiveGrid.columns(availableWidth: 360, targetCardWidth: 150),
        2,
      );
      expect(
        AdaptiveGrid.columns(availableWidth: 700, targetCardWidth: 150),
        4,
      );
      expect(
        AdaptiveGrid.columns(availableWidth: 1000, targetCardWidth: 150),
        6,
      );
    });
  });
}
