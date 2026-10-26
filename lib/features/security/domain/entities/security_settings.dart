import 'package:equatable/equatable.dart';

/// App-lock grace period (PRD S20): how long the app may stay unlocked in the
/// background before it re-locks.

/// Lock timeout options.
enum LockTimeout {
  /// Lock the moment the app leaves the foreground.
  immediately(Duration.zero, 'Immediately'),

  /// Lock after a minute in the background.
  after1Minute(Duration(minutes: 1), 'After 1 minute'),

  /// Lock after five minutes in the background.
  after5Minutes(Duration(minutes: 5), 'After 5 minutes'),

  /// Lock after fifteen minutes in the background.
  after15Minutes(Duration(minutes: 15), 'After 15 minutes'),

  /// Lock after thirty minutes in the background.
  after30Minutes(Duration(minutes: 30), 'After 30 minutes');

  const LockTimeout(this.duration, this.label);

  /// Grace period before re-locking.
  final Duration duration;

  /// Human-readable label for settings.
  final String label;
}

/// Security & privacy preferences (PRD 9.7 / S20). Persisted in prefs;
/// the DB key itself lives in secure storage.
final class SecuritySettings extends Equatable {
  /// Creates settings.
  const SecuritySettings({
    this.appLock = false,
    this.lockTimeout = LockTimeout.immediately,
    this.blockScreenshots = false,
    this.pauseHistory = false,
  });

  /// Creates defaults.
  const SecuritySettings.defaults() : this();

  /// Require biometrics / device credential to open the app.
  final bool appLock;

  /// Grace period before the app re-locks in the background.
  final LockTimeout lockTimeout;

  /// Block screenshots and recents thumbnails (FLAG_SECURE).
  final bool blockScreenshots;

  /// Stop writing to the play-history table.
  final bool pauseHistory;

  /// Copies with overrides.
  SecuritySettings copyWith({
    bool? appLock,
    LockTimeout? lockTimeout,
    bool? blockScreenshots,
    bool? pauseHistory,
  }) {
    return SecuritySettings(
      appLock: appLock ?? this.appLock,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      pauseHistory: pauseHistory ?? this.pauseHistory,
    );
  }

  @override
  List<Object?> get props => [
    appLock,
    lockTimeout,
    blockScreenshots,
    pauseHistory,
  ];
}
