import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';

void main() {
  const synced = Lyrics(
    synced: true,
    lines: [
      LyricLine(text: 'zero', time: Duration(seconds: 0)),
      LyricLine(text: 'ten', time: Duration(seconds: 10)),
      LyricLine(text: 'twenty', time: Duration(seconds: 20)),
    ],
  );

  test('activeIndex tracks the current line', () {
    expect(synced.activeIndex(const Duration(seconds: 5)), 0);
    expect(synced.activeIndex(const Duration(seconds: 10)), 1);
    expect(synced.activeIndex(const Duration(seconds: 19)), 1);
    expect(synced.activeIndex(const Duration(seconds: 25)), 2);
  });

  test('activeIndex is 0 before the first timestamp', () {
    expect(synced.activeIndex(Duration.zero), 0);
  });

  test('activeIndex is null for unsynced lyrics', () {
    const plain = Lyrics(synced: false, lines: [LyricLine(text: 'a')]);
    expect(plain.activeIndex(const Duration(seconds: 5)), isNull);
  });

  test('isEmpty reflects line list', () {
    expect(const Lyrics(synced: false, lines: []).isEmpty, isTrue);
    expect(synced.isEmpty, isFalse);
  });
}
