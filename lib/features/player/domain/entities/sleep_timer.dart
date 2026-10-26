import 'package:equatable/equatable.dart';

/// Sleep timer state (PRD F17 / O3).
///
/// A timer either counts down to [endsAt] or pauses when the current track
/// finishes. Immutable: the service replaces the whole value.

/// Active sleep timer snapshot.
final class SleepTimerState extends Equatable {
  /// Creates a timer snapshot.
  const SleepTimerState({this.endsAt, this.total, this.endOfTrack = false});

  /// No timer running.
  static const SleepTimerState off = SleepTimerState();

  /// Wall-clock deadline for a minute-based timer.
  final DateTime? endsAt;

  /// Originally selected length (for preset selection + progress).
  final Duration? total;

  /// Whether playback should pause at the end of the current track.
  final bool endOfTrack;

  /// Whether a countdown or an end-of-track timer is armed.
  bool get isActive => endsAt != null || endOfTrack;

  /// Time left at [now] (zero for off / end-of-track timers).
  Duration remainingAt(DateTime now) {
    final deadline = endsAt;
    if (deadline == null) return Duration.zero;
    final left = deadline.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props => [endsAt, total, endOfTrack];
}
