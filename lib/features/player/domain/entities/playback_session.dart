import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Snapshot of the playback session persisted between app launches
// (PRD S06: "queue + position saved every 5 s and on pause; restored paused").

/// Immutable snapshot of what was playing.
final class PlaybackSession extends Equatable {
  /// Creates a session snapshot.
  const PlaybackSession({
    required this.queue,
    required this.index,
    this.position = Duration.zero,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
  });

  /// Queue at the moment of the snapshot.
  final List<Track> queue;

  /// Index of the current track inside [queue].
  final int index;

  /// Position of the current track.
  final Duration position;

  /// Shuffle flag.
  final bool shuffle;

  /// Repeat mode.
  final RepeatMode repeat;

  /// True when there is nothing worth restoring.
  bool get isEmpty => queue.isEmpty;

  /// Current track of the snapshot, or null when empty.
  Track? get current {
    if (queue.isEmpty) return null;
    return queue[index.clamp(0, queue.length - 1)];
  }

  @override
  List<Object?> get props => [queue, index, position, shuffle, repeat];
}
