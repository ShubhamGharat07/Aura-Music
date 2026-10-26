import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

// Sealed player events (PRD 4.1). Hand-written (no codegen) but sealed:
// BLoCs exhaustively switch on them.

/// Base player event.
sealed class PlayerEvent extends Equatable {
  /// Creates an event.
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Loads a queue and starts at [startIndex].
final class PlayerQueueRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueRequested(this.tracks, {this.startIndex = 0});

  /// Tracks to enqueue.
  final List<Track> tracks;

  /// Index to start from.
  final int startIndex;

  @override
  List<Object?> get props => [tracks, startIndex];
}

/// Plays a single track (queue = [track]).
final class PlayerTrackRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerTrackRequested(this.track);

  /// Track to play.
  final Track track;

  @override
  List<Object?> get props => [track];
}

/// Toggles play / pause.
final class PlayerPlayPauseToggled extends PlayerEvent {
  /// Creates the event.
  const PlayerPlayPauseToggled();
}

/// Skips to the next track.
final class PlayerNextRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerNextRequested();
}

/// Reorders the queue. Indices are in the full queue; [newIndex] is the final
/// destination index (already adjusted for the removed item, as emitted by
/// ReorderableListView's `onReorderItem`).
final class PlayerQueueReordered extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueReordered(this.oldIndex, this.newIndex);

  /// Source index.
  final int oldIndex;

  /// Destination index.
  final int newIndex;

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Removes the queue item at [index] (full-queue index).
final class PlayerQueueItemRemoved extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueItemRemoved(this.index);

  /// Queue index to remove.
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Clears the up-next queue (the current track keeps playing).
final class PlayerQueueCleared extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueCleared();
}

/// Shuffles the up-next queue.
final class PlayerQueueShuffled extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueShuffled();
}

/// Appends [track] to the end of the queue (starts playback when idle).
final class PlayerQueueTrackAppended extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueTrackAppended(this.track);

  /// Track to append.
  final Track track;

  @override
  List<Object?> get props => [track];
}

/// Inserts [track] right after the current track.
final class PlayerQueueTrackPlayNext extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueTrackPlayNext(this.track);

  /// Track to play next.
  final Track track;

  @override
  List<Object?> get props => [track];
}

/// Jumps to the queue item at [index] and plays it.
final class PlayerQueueSelected extends PlayerEvent {
  /// Creates the event.
  const PlayerQueueSelected(this.index);

  /// Queue index to play.
  final int index;

  @override
  List<Object?> get props => [index];
}

/// Goes back to the previous track.
final class PlayerPreviousRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerPreviousRequested();
}

/// Seeks to a position (position lives in the controller, not state).
final class PlayerSeekRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerSeekRequested(this.position);

  /// Target position.
  final Duration position;

  @override
  List<Object?> get props => [position];
}

/// Toggles shuffle.
final class PlayerShuffleToggled extends PlayerEvent {
  /// Creates the event.
  const PlayerShuffleToggled();
}

/// Cycles the repeat mode.
final class PlayerRepeatCycled extends PlayerEvent {
  /// Creates the event.
  const PlayerRepeatCycled();
}

/// Toggles the like state for [trackId].
final class PlayerLikeToggled extends PlayerEvent {
  /// Creates the event.
  const PlayerLikeToggled(this.trackId);

  /// Track id to toggle.
  final String trackId;

  @override
  List<Object?> get props => [trackId];
}

/// Internal: the current track reached its end.
final class PlayerTrackCompleted extends PlayerEvent {
  /// Creates the event.
  const PlayerTrackCompleted();
}

/// Internal: the controller reported a transport status change.
final class PlayerPlaybackStatusChanged extends PlayerEvent {
  /// Creates the event.
  const PlayerPlaybackStatusChanged(this.status);

  /// New transport status.
  final PlaybackStatus status;

  @override
  List<Object?> get props => [status];
}

/// Internal: the audio engine reported a fatal playback error.
final class PlayerPlaybackError extends PlayerEvent {
  /// Creates the event.
  const PlayerPlaybackError(this.message);

  /// Human-readable engine message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Internal: the persisted liked set changed (from the library stream).
final class PlayerLikedChanged extends PlayerEvent {
  /// Creates the event.
  const PlayerLikedChanged(this.likedIds);

  /// Authoritative liked track ids.
  final Set<String> likedIds;

  @override
  List<Object?> get props => [likedIds];
}

/// Restores the last playback session (PRD S06). Sent once at startup; a
/// no-op when a session is already active.
final class PlayerSessionRestoreRequested extends PlayerEvent {
  /// Creates the event.
  const PlayerSessionRestoreRequested();
}

/// Replaces the queue with state shared by a party session (PRD S06 "listen
/// together") and resumes at the host's position. The host owns the transport
/// flag, so [playing] decides whether playback starts.
final class PlayerSnapshotApplied extends PlayerEvent {
  /// Creates the event.
  const PlayerSnapshotApplied({
    required this.tracks,
    required this.index,
    this.position = Duration.zero,
    this.playing = false,
    this.shuffle = false,
    this.repeat = RepeatMode.off,
  });

  /// Queue shared by the host.
  final List<Track> tracks;

  /// Index of the shared current track.
  final int index;

  /// Position the host is at.
  final Duration position;

  /// Whether the host is playing.
  final bool playing;

  /// Shuffle flag on the host.
  final bool shuffle;

  /// Repeat mode on the host.
  final RepeatMode repeat;

  @override
  List<Object?> get props => [
    tracks,
    index,
    position,
    playing,
    shuffle,
    repeat,
  ];
}
