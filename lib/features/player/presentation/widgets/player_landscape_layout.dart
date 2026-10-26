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

// Compact-height (phone landscape) Now Playing: two columns (PRD S06).

/// Landscape (short height) layout: artwork left, controls right.
final class PlayerLandscapeLayout extends StatelessWidget {
  /// Creates the layout.
  const PlayerLandscapeLayout({
    super.key,
    required this.bloc,
    required this.state,
    required this.accent,
    this.onCollapse,
    this.onMore,
    this.onLyrics,
    this.onQueue,
    this.onDownload,
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

  /// Open the lyrics tab.
  final VoidCallback? onLyrics;

  /// Open the queue tab.
  final VoidCallback? onQueue;

  /// Download the current track for offline playback.
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack!;
    final controller = bloc.controller;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 340,
                  maxHeight: 340,
                ),
                child: PlayerArtwork(
                  accent: accent,
                  artUrl: track.artUrl,
                  onNext: () => bloc.add(const PlayerNextRequested()),
                  onPrevious: () => bloc.add(const PlayerPreviousRequested()),
                  onDoubleTap: () => bloc.add(PlayerLikeToggled(track.id)),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: onCollapse,
                            icon: Icon(Icons.expand_more_rounded, size: 28.r),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onMore,
                            icon: const Icon(Icons.more_vert_rounded),
                          ),
                        ],
                      ),
                      TrackInfo(
                        track: track,
                        liked: state.isLiked(track.id),
                        accent: accent,
                        onLike: () => bloc.add(PlayerLikeToggled(track.id)),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      SeekBar(
                        position: controller.position,
                        duration: controller.duration,
                        buffered: controller.buffered,
                        accent: accent,
                        onSeek: (d) => bloc.add(PlayerSeekRequested(d)),
                      ),
                      SizedBox(height: AppSpacing.sm),
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
                      SizedBox(height: AppSpacing.sm),
                      BottomActions(
                        onLyrics: onLyrics,
                        onQueue: onQueue,
                        onDownload: onDownload,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
