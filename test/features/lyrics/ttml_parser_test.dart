import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/lyrics/data/ttml_parser.dart';

void main() {
  test('detects TTML vs LRC', () {
    expect(TtmlParser.looksLikeTtml('<tt xmlns="x"></tt>'), isTrue);
    expect(TtmlParser.looksLikeTtml('  <tt/>'), isTrue);
    expect(TtmlParser.looksLikeTtml('[00:01.00]hi'), isFalse);
  });

  test('parses <p> lines, strips word spans and unescapes entities', () {
    const ttml =
        '<tt><body><div>'
        '<p begin="28.189" end="29.917" itunes:key="L1">'
        '<span begin="28.189">Kayar</span> <span>jo</span>&amp;more</p>'
        '<p begin="30.262" end="32.291"><span>Woh</span> shayar</p>'
        '</div></body></tt>';

    final lyrics = TtmlParser.toLyrics(ttml)!;

    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.map((l) => l.text), <String>[
      'Kayar jo&more',
      'Woh shayar',
    ]);
    expect(lyrics.lines.first.time, const Duration(milliseconds: 28189));
    expect(lyrics.lines[1].time, const Duration(milliseconds: 30262));
  });

  test('supports clock timestamps and sorts out-of-order lines', () {
    const ttml = '<p begin="1:02.500">second</p><p begin="0:05.000">first</p>';

    final lyrics = TtmlParser.toLyrics(ttml)!;

    expect(lyrics.lines.map((l) => l.text), <String>['first', 'second']);
    expect(lyrics.lines.first.time, const Duration(seconds: 5));
    expect(
      lyrics.lines.last.time,
      const Duration(seconds: 62, milliseconds: 500),
    );
  });

  test('lines without a begin are kept as unsynced', () {
    const ttml = '<p>no timing here</p><p>another line</p>';

    final lyrics = TtmlParser.toLyrics(ttml)!;

    expect(lyrics.synced, isFalse);
    expect(lyrics.lines.map((l) => l.text), <String>[
      'no timing here',
      'another line',
    ]);
    expect(lyrics.lines.every((l) => l.time == null), isTrue);
  });

  test('returns null when there is nothing to read', () {
    expect(TtmlParser.toLyrics(''), isNull);
    expect(TtmlParser.toLyrics('<tt><body></body></tt>'), isNull);
  });
}
