import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/player/domain/entities/sleep_timer.dart';

/// Counts down and pauses transport when the sleep timer expires (PRD F17).
///
/// Owns the wall-clock ticker so screens stay rebuild-free: widgets listen to
/// [state]/[remaining] with `ValueListenableBuilder`, and expiry calls the
/// single transport owner ([PlaybackController]) instead of duplicating
/// playback state in another BLoC.
final class SleepTimerService {
  /// Creates the service and listens for track completion (end-of-track mode).
  SleepTimerService(this._controller) {
    _completed = _controller.onCompleted.listen((_) {
      if (state.value.endOfTrack) unawaited(_expire());
    });
  }

  final PlaybackController _controller;

  /// Current timer snapshot.
  final ValueNotifier<SleepTimerState> state = ValueNotifier(
    SleepTimerState.off,
  );

  /// Ticking remainder for the active minute timer (zero while inactive).
  final ValueNotifier<Duration> remaining = ValueNotifier(Duration.zero);

  Timer? _ticker;
  StreamSubscription<void>? _completed;

  /// Arms a minute-based timer, replacing any existing one.
  void start(Duration duration) {
    assert(duration > Duration.zero, 'Sleep timer must be positive.');
    _ticker?.cancel();
    final now = DateTime.now();
    state.value = SleepTimerState(endsAt: now.add(duration), total: duration);
    remaining.value = duration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Arms an end-of-track timer (pauses when the current track completes).
  void startEndOfTrack() {
    _ticker?.cancel();
    _ticker = null;
    remaining.value = Duration.zero;
    state.value = const SleepTimerState(endOfTrack: true);
  }

  /// Cancels any armed timer.
  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    remaining.value = Duration.zero;
    state.value = SleepTimerState.off;
  }

  void _tick() {
    final left = state.value.remainingAt(DateTime.now());
    if (left <= Duration.zero) {
      unawaited(_expire());
      return;
    }
    remaining.value = left;
  }

  Future<void> _expire() async {
    final wasActive = state.value.isActive;
    cancel();
    if (wasActive) await _controller.pause();
  }

  /// Cancels the timer and releases subscriptions.
  void dispose() {
    cancel();
    unawaited(_completed?.cancel());
    _completed = null;
  }
}
