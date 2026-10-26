import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/greeting.dart';

void main() {
  group('timeGreeting', () {
    test('morning before noon', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 0)), 'Good morning');
      expect(timeGreeting(DateTime(2026, 1, 1, 11, 59)), 'Good morning');
    });

    test('afternoon noon to 17', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 12)), 'Good afternoon');
      expect(timeGreeting(DateTime(2026, 1, 1, 16, 59)), 'Good afternoon');
    });

    test('evening from 17', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 17)), 'Good evening');
      expect(timeGreeting(DateTime(2026, 1, 1, 23)), 'Good evening');
    });
  });
}
