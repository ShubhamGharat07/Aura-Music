import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';

/// Parses LRC-format synced lyrics and plain lyrics into [Lyrics].
///
/// LRC line: `[mm:ss.xx]text` (one or more timestamp tags may prefix a line).
/// Metadata tags (`[ar:`, `[ti:`, `[offset:` …) are ignored.

/// LRC / plain-lyrics parser.
abstract final class LrcParser {
  static final RegExp _tag = RegExp(
    r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]',
  );

  /// Builds [Lyrics] from a synced and/or plain source, or null when empty.
  static Lyrics? build({String? synced, String? plain}) {
    final syncedLines = parseSynced(synced);
    if (syncedLines.isNotEmpty) {
      return Lyrics(lines: syncedLines, synced: true);
    }
    final plainLines = parsePlain(plain);
    if (plainLines.isNotEmpty) {
      return Lyrics(lines: plainLines, synced: false);
    }
    return null;
  }

  /// Parses [source] into timed lines (sorted). Empty when no timestamps.
  static List<LyricLine> parseSynced(String? source) {
    if (source == null || source.trim().isEmpty) return const [];
    final lines = <LyricLine>[];
    for (final raw in source.split('\n')) {
      final matches = _tag.allMatches(raw).toList();
      if (matches.isEmpty) continue;
      final text = raw.replaceAll(_tag, '').trim();
      if (text.isEmpty) continue;
      for (final match in matches) {
        lines.add(LyricLine(text: text, time: _toDuration(match)));
      }
    }
    lines.sort(
      (a, b) => (a.time ?? Duration.zero).compareTo(b.time ?? Duration.zero),
    );
    return lines;
  }

  /// Parses [source] into untimed lines.
  static List<LyricLine> parsePlain(String? source) {
    if (source == null || source.trim().isEmpty) return const [];
    return source
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => LyricLine(text: l))
        .toList(growable: false);
  }

  static Duration _toDuration(RegExpMatch match) {
    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fraction = match.group(3);
    var millis = 0;
    if (fraction != null) {
      // 1 digit = tenths, 2 = hundredths, 3 = millis.
      millis = int.parse(fraction.padRight(3, '0'));
    }
    return Duration(minutes: minutes, seconds: seconds, milliseconds: millis);
  }
}
