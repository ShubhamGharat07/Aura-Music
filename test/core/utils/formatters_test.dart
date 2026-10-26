import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/formatters.dart';

void main() {
  group('formatDuration', () {
    test('pads seconds to m:ss', () {
      expect(formatDuration(Duration.zero), '0:00');
      expect(formatDuration(const Duration(seconds: 5)), '0:05');
      expect(formatDuration(const Duration(minutes: 3, seconds: 7)), '3:07');
    });

    test('switches to h:mm:ss past an hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
      expect(formatDuration(const Duration(hours: 2)), '2:00:00');
    });
  });

  group('formatBytes', () {
    test('handles bytes, KB, MB and GB', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(1024 * 1024 * 5), '5 MB');
      expect(formatBytes(1024 * 1024 * 1024 * 2 + 1024 * 1024 * 512), '2.5 GB');
    });
  });

  group('formatCount', () {
    test('compacts thousands and millions', () {
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
      expect(formatCount(1000), '1.0K');
      expect(formatCount(1500), '1.5K');
      expect(formatCount(1000000), '1.0M');
      expect(formatCount(12345678), '12.3M');
    });
  });
}
