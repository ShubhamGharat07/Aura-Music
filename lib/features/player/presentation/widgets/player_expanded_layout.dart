import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/seek_bar.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';
import 'package:aura_music/features/player/presentation/widgets/player_artwork.dart';
import 'package:aura_music/features/player/presentation/widgets/player_common_widgets.dart';
import 'package:aura_music/features/player/presentation/widgets/player_controls.dart';
import 'package:aura_music/features/player/presentation/widgets/player_side_panel.dart';

// Expanded / Large Now Playing (PRD S06): docked player column on the left
// plus an always-there Lyrics | Queue panel on the right.

/// Docked layout for tablets / large windows.
final class PlayerExpandedLayout extends StatelessWidget {
  /// Creates the layout.
  const PlayerExpandedLayout({
    super.key,
    required this.bloc,
    required this.state,
    required this.accent,
    required this.showPanel,
    required this.panelTab,
    this.onCollapse,
    this.onMore,
    this.onTogglePanel,
    this.onLyrics,
    this.onQueue,
    this.onTabSelected,
    this.onDownload,
    this.onParty,
    this.partyActive = false,
  });

  /// Player bloc.
  final PlayerBloc bloc;

  /// Player state.
  final PlayerState state;

  /// Accent colour.
  final Color accent;

  /// Whether the side panel is visible.
  final bool showPanel;

  /// Active side-panel tab (`0` lyrics, `1` queue).
  final int panelTab;

  /// Collapse callback.
  final VoidCallback? onCollapse;

  /// Overflow menu callback.
  final VoidCallback? onMore;

  /// Toggle the side panel.
  final VoidCallback? onTogglePanel;

  /// Show the lyrics tab.
  final VoidCallback? onLyrics;

  /// Show the queue tab.
  final VoidCallback? onQueue;

  /// Tab change from the panel's segmented control.
  final ValueChanged<int>? onTabSelected;

  /// Download the current track for offline playback.
  final VoidCallback? onDownload;

  /// Listen together callback (PRD S06); gets the button's context to anchor to.
  final ValueChanged<BuildContext>? onParty;

  /// Whether a party session is running.
  final bool partyActive;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack!;
    final controller = bloc.controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - AppSpacing.xl * 2;
        final panelWidth = (available * 0.34).clamp(320.0, 400.0);
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  children: [
                    PlayerHeader(
                      onCollapse: onCollapse,
                      onParty: onParty,
                      partyActive: partyActive,
                      onMore: onMore,
                    ),
                    Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 380,
                        maxHeight: 380,
                      ),
                      child: PlayerArtwork(
                        accent: accent,
                        artUrl: track.artUrl,
                        onNext: () => bloc.add(const PlayerNextRequested()),
                        onPrevious: () =>
                            bloc.add(const PlayerPreviousRequested()),
                        onDoubleTap: () =>
                            bloc.add(PlayerLikeToggled(track.id)),
                      ),
                    ),
                    SizedBox(height: 28.w),
                    TrackInfo(
                      track: track,
                      liked: state.isLiked(track.id),
                      accent: accent,
                      centered: true,
                      onLike: () => bloc.add(PlayerLikeToggled(track.id)),
                    ),
                    SizedBox(height: 8.w),
                    SeekBar(
                      position: controller.position,
                      duration: controller.duration,
                      buffered: controller.buffered,
                      accent: accent,
                      onSeek: (d) => bloc.add(PlayerSeekRequested(d)),
                    ),
                    SizedBox(height: 8.w),
                    PlayerControls(
                      accent: accent,
                      status: state.status,
                      shuffle: state.shuffle,
                      repeat: state.repeat,
                      onPlayPause: () =>
                          bloc.add(const PlayerPlayPauseToggled()),
                      onNext: () => bloc.add(const PlayerNextRequested()),
                      onPrevious: () =>
                          bloc.add(const PlayerPreviousRequested()),
                      onShuffle: () => bloc.add(const PlayerShuffleToggled()),
                      onRepeat: () => bloc.add(const PlayerRepeatCycled()),
                    ),
                    Spacer(),
                    BottomActions(
                      onLyrics: onLyrics,
                      onQueue: onQueue,
                      onDownload: onDownload,
                    ),
                    SizedBox(height: 8.w),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              if (showPanel)
                SizedBox(
                  width: panelWidth,
                  child: PlayerSidePanel(
                    accent: accent,
                    state: state,
                    position: controller.position,
                    selectedTab: panelTab,
                    onTabSelected: onTabSelected,
                    onClose: onTogglePanel,
                    onSelectQueue: (i) => bloc.add(PlayerQueueSelected(i)),
                    onReorderQueue: (o, n) =>
                        bloc.add(PlayerQueueReordered(o, n)),
                    onRemoveQueue: (i) => bloc.add(PlayerQueueItemRemoved(i)),
                    onClearQueue: () => bloc.add(const PlayerQueueCleared()),
                    onShuffleQueue: () => bloc.add(const PlayerQueueShuffled()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
