import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Listen together (PRD S06): the host-authoritative playback state it shares
// with its guests. Mirrors the persisted PlaybackSession but carries the
// transport flag, because a live share has to know whether to play or pause.

/// Immutable snapshot of what the host is playing.
final class PartySnapshot extends Equatable {
  /// Creates a snapshot.
  const PartySnapshot({
    required this.queue,
    required this.index,
    this.position = Duration.zero,
    this.playing = false,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
  });

  /// Queue at the moment of the snapshot.
  final List<Track> queue;

  /// Index of the current track inside [queue].
  final int index;

  /// Position of the current track.
  final Duration position;

  /// Whether the host is playing.
  final bool playing;

  /// Shuffle flag.
  final bool shuffle;

  /// Repeat mode.
  final RepeatMode repeat;

  /// True when there is nothing to follow.
  bool get isEmpty => queue.isEmpty;

  /// Current track of the snapshot, or null when empty.
  Track? get current {
    if (queue.isEmpty) return null;
    return queue[index.clamp(0, queue.length - 1)];
  }

  /// Identity of the queue shape: everything except the playback position.
  /// Two snapshots with the same key only differ by position/transport, which
  /// is what lets the host send a small tick instead of the whole queue.
  String get shapeKey =>
      '${queue.map((t) => t.id).join('|')}#$index#$shuffle#${repeat.name}';

  @override
  List<Object?> get props => [queue, index, position, playing, shuffle, repeat];
}
