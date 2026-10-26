import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/lyrics/data/lrc_parser.dart';

void main() {
  group('LrcParser.parseSynced', () {
    test('parses timestamps, skips metadata, strips tags', () {
      const lrc = '''
[ar:Aurora Skies]
[ti:Neon Horizon]
[00:12.00]Neon on the skyline
[00:15.50]We were only passing through
''';
      final lines = LrcParser.parseSynced(lrc);

      expect(lines.length, 2);
      expect(lines.first.text, 'Neon on the skyline');
      expect(lines.first.time, const Duration(seconds: 12));
      expect(lines.last.time, const Duration(seconds: 15, milliseconds: 500));
    });

    test('handles multiple tags on one line and sorts by time', () {
      final lines = LrcParser.parseSynced('[00:20.00][00:10.00]Repeat me');
      expect(lines.length, 2);
      expect(lines.first.time, const Duration(seconds: 10));
      expect(lines.last.time, const Duration(seconds: 20));
      expect(lines.every((l) => l.text == 'Repeat me'), isTrue);
    });

    test('interprets 2-digit fraction as centiseconds', () {
      final lines = LrcParser.parseSynced('[01:02.25]Half');
      expect(
        lines.single.time,
        const Duration(minutes: 1, seconds: 2, milliseconds: 250),
      );
    });

    test('returns empty when there are no timestamps', () {
      expect(LrcParser.parseSynced('just plain words'), isEmpty);
      expect(LrcParser.parseSynced(null), isEmpty);
    });
  });

  group('LrcParser.build', () {
    test('prefers synced lines over plain', () {
      final lyrics = LrcParser.build(
        synced: '[00:01.00]timed line',
        plain: 'plain line',
      );
      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isTrue);
      expect(lyrics.lines.single.text, 'timed line');
    });

    test('falls back to plain lines', () {
      final lyrics = LrcParser.build(plain: 'one\ntwo\n\nthree');
      expect(lyrics, isNotNull);
      expect(lyrics!.synced, isFalse);
      expect(lyrics.lines.map((l) => l.text), ['one', 'two', 'three']);
      expect(lyrics.lines.every((l) => l.time == null), isTrue);
    });

    test('returns null when nothing is present', () {
      expect(LrcParser.build(synced: null, plain: '   '), isNull);
      expect(LrcParser.build(), isNull);
    });
  });
}
