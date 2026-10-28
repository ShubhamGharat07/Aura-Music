import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Album artwork for the Now Playing screen (F04 gestures): swipe the art
// left/right to change track, double-tap to like. Pure presentation.

/// Player artwork with swipe / double-tap gestures.
final class PlayerArtwork extends StatelessWidget {
  /// Creates the artwork.
  const PlayerArtwork({
    super.key,
    required this.accent,
    this.artUrl,
    this.onNext,
    this.onPrevious,
    this.onDoubleTap,
    this.radius = 20,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) {
          onNext?.call();
        } else if (velocity > 200) {
          onPrevious?.call();
        }
      },
      onDoubleTap: onDoubleTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Decode close to the on-screen size instead of a fixed 720 px.
            // Tablets get sharper art; phones stop wasting memory on a
            // bitmap larger than the slot.
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final cacheSize = (constraints.maxWidth * dpr).round().clamp(
              256,
              1024,
            );
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
