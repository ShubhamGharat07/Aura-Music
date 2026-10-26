// App-wide immutable constants (PRD sections 9-10).
//
// No magic numbers in widgets: import from here or [AppTokens].

/// Network timeouts.
abstract final class AppConstants {
  /// Short timeout for lightweight calls (search suggestions, update check).
  static const Duration shortTimeout = Duration(seconds: 10);

  /// Long timeout for stream resolution / downloads metadata.
  static const Duration longTimeout = Duration(seconds: 20);

  /// Minimum free-space multiplier required before an OTA download.
  static const int updateFreeSpaceFactor = 2;

  /// How often the update check may run at most.
  static const Duration updateCheckInterval = Duration(hours: 12);

  /// JSON manifest read by the in-app update checker. Empty = this build has
  /// no update channel, so Settings > Updates reports it as not configured.
  static const String updateManifestUrl = '';

  /// Queue + position autosave interval.
  static const Duration queueAutosaveInterval = Duration(seconds: 5);

  /// Listen together (PRD S06): how often the host re-shares its position.
  static const Duration partyPublishInterval = Duration(seconds: 5);

  /// Listen together: how far a guest may drift before it re-seeks.
  static const Duration partySyncTolerance = Duration(milliseconds: 400);

  /// Listen together: how long a scan for nearby sessions runs.
  static const Duration partyScanTimeout = Duration(seconds: 20);

  /// Listen together: how long to wait for the GATT link before giving up.
  static const Duration partyConnectTimeout = Duration(seconds: 15);

  /// Search suggestion debounce.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Stream-failure auto-skip delay (PRD S06).
  static const Duration streamFailSkipDelay = Duration(milliseconds: 1500);

  /// Toast duration.
  static const Duration toastDuration = Duration(seconds: 3);

  /// Default image disk-cache cap in bytes (200 MB).
  static const int imageCacheBytes = 200 * 1024 * 1024;

  /// Minimum touch target (dp).
  static const double minTouchTarget = 48;
}
