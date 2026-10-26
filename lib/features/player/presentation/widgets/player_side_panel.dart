import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';
import 'package:aura_music/features/player/presentation/widgets/lyrics_panel.dart';
import 'package:aura_music/features/player/presentation/widgets/queue_panel.dart';

// Right-side tabbed panel for Expanded/Large (S06/S07/S08). Lyrics and
// Queue share one glass panel; tab choice is ephemeral UI state (hooks).

/// Lyrics | Queue side panel.
final class PlayerSidePanel extends HookWidget {
  /// Creates the side panel.
  const PlayerSidePanel({
    super.key,
    required this.accent,
    required this.state,
    required this.position,
    this.initialTab = 0,
    this.selectedTab,
    this.onTabSelected,
    this.onSelectQueue,
    this.onReorderQueue,
    this.onRemoveQueue,
    this.onClearQueue,
    this.onShuffleQueue,
    this.onClose,
  });

  /// Accent colour.
  final Color accent;

  /// Player state (drives queue content).
  final PlayerState state;

  /// Position notifier.
  final ValueListenable<Duration> position;

  /// Tab shown when the panel opens (`0` lyrics, `1` queue).
  final int initialTab;

  /// Controlled tab index; falls back to internal state when null.
  final int? selectedTab;

  /// Tab change callback (for an externally owned [selectedTab]).
  final ValueChanged<int>? onTabSelected;

  /// Queue row tap callback (full-queue index).
  final ValueChanged<int>? onSelectQueue;

  /// Queue reorder callback (full-queue indices).
  final void Function(int oldIndex, int newIndex)? onReorderQueue;

  /// Queue row removal callback (full-queue index).
  final ValueChanged<int>? onRemoveQueue;

  /// Clear the up-next queue.
  final VoidCallback? onClearQueue;

  /// Shuffle the up-next queue.
  final VoidCallback? onShuffleQueue;

  /// Close the panel (collapse back to the player bar).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final internalTab = useState(initialTab.clamp(0, 1).toInt());
    final activeTab = selectedTab ?? internalTab.value;
    void selectTab(int next) {
      internalTab.value = next;
      onTabSelected?.call(next);
    }

    return GlassSurface(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Lyrics')),
                    ButtonSegment(value: 1, label: Text('Queue')),
                  ],
                  selected: {activeTab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => selectTab(s.first),
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close panel',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Expanded(
            child: activeTab == 0
                ? BlocBuilder<LyricsCubit, LyricsState>(
                    builder: (context, lyrics) => LyricsPanel(
                      state: lyrics,
                      position: position,
                      accent: accent,
                      fontScale: 1.05,
                    ),
                  )
                : QueuePanel(
                    queue: state.queue,
                    currentIndex: state.currentIndex,
                    accent: accent,
                    onSelect: onSelectQueue,
                    onReorder: onReorderQueue,
                    onRemove: onRemoveQueue,
                    onClear: onClearQueue,
                    onShuffle: onShuffleQueue,
                  ),
          ),
        ],
      ),
    );
  }
}
