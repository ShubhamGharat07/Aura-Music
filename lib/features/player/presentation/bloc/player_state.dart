import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Immutable player state (PRD 4.1). Position is intentionally NOT here:
// it is a ValueListenable on the PlaybackController.

/// Player BLoC state.
final class PlayerState extends Equatable {
  /// Creates player state.
  const PlayerState({
    this.status = PlaybackStatus.idle,
    this.queue = const [],
    this.currentIndex = 0,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
    this.likedIds = const {},
    this.error,
  });

  /// Transport status.
  final PlaybackStatus status;

  /// Up-next queue.
  final List<Track> queue;

  /// Index of the current track within [queue].
  final int currentIndex;

  /// Shuffle enabled.
  final bool shuffle;

  /// Repeat mode.
  final RepeatMode repeat;

  /// Liked track ids.
  final Set<String> likedIds;

  /// Error message (when [status] is [PlaybackStatus.error]).
  final String? error;

  /// Current track, or null when idle.
  Track? get currentTrack => currentIndex >= 0 && currentIndex < queue.length
      ? queue[currentIndex]
      : null;

  /// Tracks queued after the current one (PRD S07 "Up next").
  List<Track> get upNext => currentIndex + 1 < queue.length
      ? queue.sublist(currentIndex + 1)
      : const [];

  /// Whether a given track is liked.
  bool isLiked(String id) => likedIds.contains(id);

  /// Whether audio is playing.
  bool get isPlaying => status == PlaybackStatus.playing;

  /// Copies with overrides. [clearTrack] resets to idle.
  PlayerState copyWith({
    PlaybackStatus? status,
    List<Track>? queue,
    int? currentIndex,
    bool? shuffle,
    RepeatMode? repeat,
    Set<String>? likedIds,
    String? error,
  }) {
    return PlayerState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
      likedIds: likedIds ?? this.likedIds,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    queue,
    currentIndex,
    shuffle,
    repeat,
    likedIds,
    error,
  ];
}
