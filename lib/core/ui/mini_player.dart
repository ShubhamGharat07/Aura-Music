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
            borderRadius: 20.r,
            sigma: 24,
            tier: tier,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10.w, 8.w, 3.w, 8.w),
                    child: Row(
                      children: [
                        _Art(accent: accent, artUrl: track.artUrl),
                        SizedBox(width: 12.w),
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
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: state.isPlaying ? 'Pause' : 'Play',
                          onPressed: () =>
                              bloc.add(const PlayerPlayPauseToggled()),
                          iconSize: 26.r,
                          color: AppColors.textPrimary,
                          icon: AnimatedSwitcher(
                            duration: AppDurations.fast,
                            switchInCurve: AppCurves.out,
                            switchOutCurve: AppCurves.out,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation.drive(
                                      Tween<double>(begin: 0.92, end: 1),
                                    ),
                                    child: child,
                                  ),
                                ),
                            child: loading
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    width: 18.r,
                                    height: 18.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                : Icon(
                                    key: ValueKey(state.isPlaying),
                                    state.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next',
                          onPressed: () =>
                              bloc.add(const PlayerNextRequested()),
                          iconSize: 24.r,
                          color: AppColors.textSecondary,
                          icon: const Icon(Icons.skip_next_rounded),
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
///
/// Driven by the position notifier directly: playback progress repaints this
/// two-pixel strip instead of rebuilding the mini player's row every tick.
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
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          height: 3,
          width: double.infinity,
          child: CustomPaint(
            painter: _MiniProgressPainter(
              position: position,
              duration: duration,
              accent: accent,
            ),
          ),
        ),
      ),
    );
  }
}

final class _MiniProgressPainter extends CustomPainter {
  _MiniProgressPainter({
    required this.position,
    required this.duration,
    required this.accent,
  }) : super(repaint: position);

  final ValueListenable<Duration> position;
  final Duration duration;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final total = duration.inMilliseconds;
    final progress = total <= 0
        ? 0.0
        : (position.value.inMilliseconds / total).clamp(0.0, 1.0);
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    if (progress <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, size.height),
        radius,
      ),
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_MiniProgressPainter oldDelegate) =>
      oldDelegate.duration != duration || oldDelegate.accent != accent;
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
      width: 43.r,
      height: 43.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: url == null
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                width: 43.r,
                height: 43.r,
                fit: BoxFit.cover,
                memCacheWidth: 132,
                memCacheHeight: 132,
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
