import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/utils/color_from_id.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';

/// Mini player above the bar/rail (PRD O6). Reads [PlayerBloc] state;
/// tap expands Now Playing.
final class MiniPlayer extends StatelessWidget {
  /// Creates the mini player.
  const MiniPlayer({super.key, this.tier = GlassTier.high, this.onTap});

  /// Glass tier.
  final GlassTier tier;

  /// Tap = open the full player.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final track = state.currentTrack;
        // First launch (no session): the chrome stays compact with just the
        // nav bar instead of showing an empty "Nothing playing" card.
        if (track == null) return const SizedBox.shrink();
        final accent = accentFromId(track.id);
        final loading = state.status == PlaybackStatus.loading;
        final bloc = context.read<PlayerBloc>();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GlassSurface(
            borderRadius: 18.r,
            sigma: 28,
            tier: tier,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      10.w,
                      AppSpacing.sm,
                      6.w,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _Art(accent: accent, artUrl: track.artUrl),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.subtitle.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: state.isPlaying ? 'Pause' : 'Play',
                          onPressed: () =>
                              bloc.add(const PlayerPlayPauseToggled()),
                          icon: Container(
                            width: 36.r,
                            height: 36.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: loading
                                ? Padding(
                                    padding: EdgeInsets.all(9.r),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: accent,
                                    ),
                                  )
                                : Icon(
                                    state.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 22.r,
                                    color: AppColors.textPrimary,
                                  ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next',
                          onPressed: () =>
                              bloc.add(const PlayerNextRequested()),
                          icon: Icon(
                            Icons.skip_next_rounded,
                            size: 24.r,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProgressLine(
                    position: bloc.controller.position,
                    duration: bloc.controller.duration,
                    accent: accent,
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

/// Thin progress line flush along the bottom edge of the mini player (PRD O6).
final class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.position,
    required this.duration,
    required this.accent,
  });

  final ValueListenable<Duration> position;
  final Duration duration;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: position,
      builder: (context, value, _) {
        final total = duration.inMilliseconds;
        final progress = total <= 0
            ? 0.0
            : (value.inMilliseconds / total).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        );
      },
    );
  }
}

/// Small track art thumbnail (real artwork when available, subtle dark glass box otherwise).
final class _Art extends StatelessWidget {
  const _Art({required this.accent, this.artUrl});

  final Color accent;
  final String? artUrl;

  @override
  Widget build(BuildContext context) {
    final url = artUrl;
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.glassBorder, width: 0.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: url == null
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                width: 44.r,
                height: 44.r,
                fit: BoxFit.cover,
                memCacheWidth: 110,
                memCacheHeight: 110,
                fadeInDuration: AppDurations.fast,
                errorWidget: (context, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.35), AppColors.bgElevated],
        ),
      ),
      child: Icon(Icons.music_note_rounded, size: 20.r, color: accent),
    );
  }
}
