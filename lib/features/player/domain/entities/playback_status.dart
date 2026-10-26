/// Playback enums (PRD S06 / F04).
library;

/// Transport status.
enum PlaybackStatus {
  /// Nothing loaded.
  idle,

  /// Resolving / buffering.
  loading,

  /// Actively playing.
  playing,

  /// Loaded but paused.
  paused,

  /// Stream or decode failed.
  error,
}

/// Repeat behaviour.
enum RepeatMode {
  /// No repeat.
  off,

  /// Repeat the whole queue.
  all,

  /// Repeat the current track.
  one,
}

extension RepeatModeX on RepeatMode {
  /// Next mode in the cycle off -> all -> one -> off.
  RepeatMode get next => switch (this) {
    RepeatMode.off => RepeatMode.all,
    RepeatMode.all => RepeatMode.one,
    RepeatMode.one => RepeatMode.off,
  };
}
