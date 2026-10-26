import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/format_count.dart';

void main() {
  test('formats counts compactly', () {
    expect(formatCompactCount(0), '0');
    expect(formatCompactCount(999), '999');
    expect(formatCompactCount(1000), '1k');
    expect(formatCompactCount(12500), '12.5k');
    expect(formatCompactCount(833000), '833k');
    expect(formatCompactCount(6713502), '6.7M');
    expect(formatCompactCount(1200000000), '1.2B');
  });
}
