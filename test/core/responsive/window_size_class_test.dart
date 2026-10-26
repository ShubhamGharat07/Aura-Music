import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/responsive/window_size_class.dart';

void main() {
  group('WindowSizeClass.ofWidth', () {
    test('classifies each band at its boundaries', () {
      expect(WindowSizeClass.ofWidth(0), WindowSizeClass.compact);
      expect(WindowSizeClass.ofWidth(599), WindowSizeClass.compact);
      expect(WindowSizeClass.ofWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.ofWidth(839), WindowSizeClass.medium);
      expect(WindowSizeClass.ofWidth(840), WindowSizeClass.expanded);
      expect(WindowSizeClass.ofWidth(1199), WindowSizeClass.expanded);
      expect(WindowSizeClass.ofWidth(1200), WindowSizeClass.large);
      expect(WindowSizeClass.ofWidth(2000), WindowSizeClass.large);
    });
  });

  group('navigationFor', () {
    test('portrait phone uses the bottom bar', () {
      expect(
        WindowSizeClass.navigationFor(width: 393, height: 852),
        ShellNavigationMode.bottomBar,
      );
    });

    test('phone landscape keeps a compact rail, not an extended one', () {
      expect(
        WindowSizeClass.navigationFor(width: 852, height: 393),
        ShellNavigationMode.compactRail,
      );
    });

    test('tablet landscape uses the extended rail', () {
      expect(
        WindowSizeClass.navigationFor(width: 1194, height: 834),
        ShellNavigationMode.extendedRail,
      );
    });

    test('expanded width with compact height falls back to compact rail', () {
      expect(
        WindowSizeClass.navigationFor(width: 1194, height: 420),
        ShellNavigationMode.compactRail,
      );
    });
  });

  group('convenience getters', () {
    test('isCompact only for compact', () {
      expect(WindowSizeClass.compact.isCompact, isTrue);
      expect(WindowSizeClass.medium.isCompact, isFalse);
    });

    test('isMediumUp is everything but compact', () {
      expect(WindowSizeClass.compact.isMediumUp, isFalse);
      expect(WindowSizeClass.medium.isMediumUp, isTrue);
      expect(WindowSizeClass.expanded.isMediumUp, isTrue);
    });

    test('isExpandedUp is expanded or large', () {
      expect(WindowSizeClass.medium.isExpandedUp, isFalse);
      expect(WindowSizeClass.expanded.isExpandedUp, isTrue);
      expect(WindowSizeClass.large.isExpandedUp, isTrue);
    });
  });
}
