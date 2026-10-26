import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/player/domain/entities/sleep_timer.dart';

void main() {
  group('SleepTimerState', () {
    test('off is inactive and has no remainder', () {
      expect(SleepTimerState.off.isActive, isFalse);
      expect(SleepTimerState.off.remainingAt(DateTime(2026)), Duration.zero);
    });

    test('counts down to the deadline', () {
      final now = DateTime(2026, 10, 20, 12);
      final timer = SleepTimerState(
        endsAt: now.add(const Duration(minutes: 5)),
        total: const Duration(minutes: 5),
      );
      expect(timer.isActive, isTrue);
      expect(timer.remainingAt(now), const Duration(minutes: 5));
      expect(
        timer.remainingAt(now.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
    });

    test('clamps a past deadline to zero', () {
      final now = DateTime(2026, 10, 20, 12);
      final timer = SleepTimerState(
        endsAt: now.subtract(const Duration(seconds: 1)),
        total: const Duration(minutes: 1),
      );
      expect(timer.remainingAt(now), Duration.zero);
    });

    test('end-of-track timers are active without a deadline', () {
      const timer = SleepTimerState(endOfTrack: true);
      expect(timer.isActive, isTrue);
      expect(timer.endsAt, isNull);
      expect(timer.remainingAt(DateTime(2026)), Duration.zero);
    });
  });
}
