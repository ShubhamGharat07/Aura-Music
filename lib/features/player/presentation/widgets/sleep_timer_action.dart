import 'package:flutter/material.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/utils/formatters.dart';
import 'package:aura_music/features/player/data/services/sleep_timer_service.dart';
import 'package:aura_music/features/player/domain/entities/sleep_timer.dart';
import 'package:aura_music/features/player/presentation/widgets/player_action.dart';
import 'package:aura_music/features/player/presentation/widgets/sleep_timer_sheet.dart';

/// Sleep-timer entry point with a live label (PRD F17 / O3): `Sleep` when off,
/// `m:ss` while counting down, `End` for end-of-track mode.

/// Compact sleep-timer action for the player action row.
final class SleepTimerAction extends StatelessWidget {
  /// Creates the action.
  const SleepTimerAction({super.key});

  @override
  Widget build(BuildContext context) {
    // Widget tests can pump the player without full DI; keep the row intact.
    if (!getIt.isRegistered<SleepTimerService>()) {
      return const PlayerAction(icon: Icons.bedtime_outlined, label: 'Sleep');
    }
    final service = getIt<SleepTimerService>();
    return ValueListenableBuilder<SleepTimerState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: service.remaining,
          builder: (context, remaining, _) {
            final active = state.isActive;
            final label = state.endOfTrack
                ? 'End'
                : state.endsAt == null
                ? 'Sleep'
                : formatDuration(remaining);
            return PlayerAction(
              icon: active ? Icons.bedtime_rounded : Icons.bedtime_outlined,
              label: label,
              color: active ? Theme.of(context).colorScheme.primary : null,
              onTap: () => showSleepTimerSheet(context),
            );
          },
        );
      },
    );
  }
}
