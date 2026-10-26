import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/ttl_cache.dart';

void main() {
  test('returns a stored value before it expires', () {
    var now = DateTime(2026, 1, 1);
    final cache = TtlCache<String, int>(
      ttl: const Duration(minutes: 2),
      clock: () => now,
    );

    cache.set('a', 1);
    now = now.add(const Duration(minutes: 1));

    expect(cache.get('a'), 1);
    expect(cache.length, 1);
  });

  test('expires a value after the ttl', () {
    var now = DateTime(2026, 1, 1);
    final cache = TtlCache<String, int>(
      ttl: const Duration(minutes: 2),
      clock: () => now,
    );

    cache.set('a', 1);
    now = now.add(const Duration(minutes: 3));

    expect(cache.get('a'), isNull);
    expect(cache.length, 0);
  });

  test('misses unknown keys and clears on demand', () {
    final cache = TtlCache<String, int>(ttl: const Duration(minutes: 1));

    expect(cache.get('missing'), isNull);
    cache.set('a', 1);
    cache.clear();

    expect(cache.get('a'), isNull);
  });
}
