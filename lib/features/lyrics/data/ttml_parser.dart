import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';

/// Converts Apple-Music-style TTML (served by Unison / Better Lyrics as
/// `richsync`) into [Lyrics].
///
/// Each `<p>` element becomes one line: its `begin` attribute (a `mm:ss.mmm`
/// clock or a bare second offset) is the line timestamp, and its inner text —
/// word-level `<span>`s and `<br/>` tags stripped — is the line text.

/// TTML (richsync) parser.
abstract final class TtmlParser {
  static final RegExp _paragraph = RegExp(
    r'<p\b([^>]*)>(.*?)</p>',
    dotAll: true,
  );
  static final RegExp _begin = RegExp(r'''\bbegin\s*=\s*"([^"]+)"''');
  static final RegExp _tag = RegExp(r'<[^>]*>');
  static final RegExp _spaces = RegExp(r'\s+');

  /// Whether [source] is TTML rather than LRC (TTML is an XML document).
  static bool looksLikeTtml(String source) => source.trimLeft().startsWith('<');

  /// Builds [Lyrics] from [source], or null when no readable lines are found.
  static Lyrics? toLyrics(String source) {
    final lines = parseLines(source);
    if (lines.isEmpty) return null;
    return Lyrics(lines: lines, synced: lines.any((line) => line.time != null));
  }

  /// Parses [source] into lines, sorted by timestamp when all are timed.
  static List<LyricLine> parseLines(String source) {
    if (source.trim().isEmpty) return const [];
    final lines = <LyricLine>[];
    for (final match in _paragraph.allMatches(source)) {
      final text = _unescape(
        match.group(2)!.replaceAll(_tag, ''),
      ).replaceAll(_spaces, ' ').trim();
      if (text.isEmpty) continue;
      lines.add(
        LyricLine(
          text: text,
          time: _toDuration(_begin.firstMatch(match.group(1)!)?.group(1)),
        ),
      );
    }
    if (lines.length > 1 && lines.every((line) => line.time != null)) {
      lines.sort((a, b) => a.time!.compareTo(b.time!));
    }
    return List<LyricLine>.unmodifiable(lines);
  }

  static Duration? _toDuration(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var total = 0.0;
    for (final part in raw.trim().split(':')) {
      final value = double.tryParse(part.trim());
      if (value == null) return null;
      total = total * 60 + value;
    }
    return Duration(milliseconds: (total * 1000).round());
  }

  static String _unescape(String value) => value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');
}
