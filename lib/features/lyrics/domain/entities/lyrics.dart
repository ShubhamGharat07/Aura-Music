import 'package:equatable/equatable.dart';

/// A single lyric line. [time] is null for unsynced (plain) lyrics.
final class LyricLine extends Equatable {
  /// Creates a lyric line.
  const LyricLine({required this.text, this.time});

  /// Line text.
  final String text;

  /// Timestamp for synced lyrics, or null.
  final Duration? time;

  @override
  List<Object?> get props => [text, time];
}

/// Track lyrics: synced (timed) or plain.
final class Lyrics extends Equatable {
  /// Creates lyrics.
  const Lyrics({required this.lines, required this.synced});

  /// All lines in order.
  final List<LyricLine> lines;

  /// Whether [lines] carry timestamps.
  final bool synced;

  /// Whether there is nothing to show.
  bool get isEmpty => lines.isEmpty;

  /// Index of the line active at [position], or null when unsynced/empty.
  /// Returns 0 before the first timestamp.
  int? activeIndex(Duration position) {
    if (!synced || lines.isEmpty) return null;
    var active = 0;
    for (var i = 0; i < lines.length; i++) {
      final time = lines[i].time;
      if (time == null) continue;
      if (time <= position) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }

  @override
  List<Object?> get props => [lines, synced];
}
