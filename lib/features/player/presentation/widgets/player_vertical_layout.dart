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

// Compact-portrait Now Playing: vertical stack (PRD S06).

/// Vertical (phone portrait) layout.
final class PlayerVerticalLayout extends StatelessWidget {
  /// Creates the layout.
  const PlayerVerticalLayout({
    super.key,
    required this.bloc,
    required this.state,
    required this.accent,
    this.onCollapse,
    this.onMore,
    this.onLyrics,
    this.onQueue,
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

  /// Collapse callback.
  final VoidCallback? onCollapse;

  /// Overflow menu callback.
  final VoidCallback? onMore;

  /// Open the lyrics tab of the side panel / sheet.
  final VoidCallback? onLyrics;

  /// Open the queue tab of the side panel / sheet.
  final VoidCallback? onQueue;

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
    final double artMax = MediaQuery.sizeOf(context).width * 0.82;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlayerHeader(
                    onCollapse: onCollapse,
                    onParty: onParty,
                    partyActive: partyActive,
                    onMore: onMore,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: artMax > 420 ? 420 : artMax,
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
                      SizedBox(height: 32.w),
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
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: BottomActions(
                      onLyrics: onLyrics,
                      onQueue: onQueue,
                      onDownload: onDownload,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
