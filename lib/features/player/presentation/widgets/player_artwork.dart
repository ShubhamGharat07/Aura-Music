import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/hooks/use_playback_motion.dart';
import 'package:aura_music/core/ui/aura_hero.dart';

// Album artwork for the Now Playing screen (F04 gestures): swipe the art
// left/right to change track, double-tap to like. Pure presentation.

/// Player artwork with swipe / double-tap gestures.
final class PlayerArtwork extends HookWidget {
  /// Creates the artwork.
  const PlayerArtwork({
    super.key,
    required this.accent,
    this.artUrl,
    this.onNext,
    this.onPrevious,
    this.onDoubleTap,
    this.radius = 20,
    this.heroTag,
    this.playing = false,
  });

  /// Accent colour for the gradient fallback.
  final Color accent;

  /// Remote artwork URL (null = gradient placeholder).
  final String? artUrl;

  /// Swipe-left callback (next).
  final VoidCallback? onNext;

  /// Swipe-right callback (previous).
  final VoidCallback? onPrevious;

  /// Double-tap callback (like).
  final VoidCallback? onDoubleTap;

  /// Corner radius.
  final double radius;

  /// Hero tag shared with the mini-player thumbnail (null = no hero).
  final Object? heroTag;

  /// Whether audio is currently playing.
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final breathe = usePlaybackMotion(context, playing: playing);
    final controller = useAnimationController(
      duration: const Duration(seconds: 4),
    );
    final scale = useMemoized(
      () => controller.drive(
        Tween(
          begin: 1.0,
          end: 1.015,
        ).chain(CurveTween(curve: Curves.easeInOutSine)),
      ),
      [controller],
    );
    useEffect(() {
      if (breathe) {
        controller.repeat(reverse: true);
      } else {
        controller.reset();
      }
      return null;
    }, [controller, breathe]);
    final art = AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decode close to the on-screen size instead of a fixed 720 px.
          // Tablets get sharper art; phones stop wasting memory on a
          // bitmap larger than the slot.
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final cacheSize = (constraints.biggest.shortestSide * dpr)
              .round()
              .clamp(256, 1024);
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (artUrl == null)
                  _placeholder()
                else
                  CachedNetworkImage(
                    imageUrl: artUrl!,
                    memCacheWidth: cacheSize,
                    memCacheHeight: cacheSize,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 220),
                    placeholder: (context, url) => _placeholder(),
                    errorWidget: (context, url, error) => _placeholder(),
                  ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 0.7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final tag = heroTag;
    final like = onDoubleTap;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) {
          onNext?.call();
        } else if (velocity > 200) {
          onPrevious?.call();
        }
      },
      onDoubleTap: like == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              like();
            },
      child: ScaleTransition(
        scale: scale,
        child: RepaintBoundary(
          child: tag == null ? art : AuraHero(tag: tag, child: art),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.55)!],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top-left highlight for the "glass" feel.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.center,
                colors: [Color(0x33FFFFFF), Colors.transparent],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.graphic_eq,
              size: 96.r,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
