import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/colors.dart';

/// Liquid-glass base surface (PRD 8.4).
/// Uses dark smoked-glass physics so vibrant album art behind the nav bar
/// or mini-player looks rich and atmospheric, never milky or cartoonish.
final class GlassSurface extends StatelessWidget {
  /// Blurred glass (counts toward the max-3-blurs budget).
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.sigma = 28,
    this.tier = GlassTier.high,
    this.padding,
    this.margin,
  }) : _fake = false;

  /// Fake glass for list items / large tablet panels (no blur).
  const GlassSurface.fake({
    super.key,
    required this.child,
    this.borderRadius = 14,
    this.padding,
    this.margin,
  }) : _fake = true,
       sigma = 0,
       tier = GlassTier.low;

  /// Child content.
  final Widget child;

  /// Corner radius.
  final double borderRadius;

  /// Blur sigma (clamped 16-32).
  final double sigma;

  /// Device tier. Low / fake skips the blur.
  final GlassTier tier;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  final bool _fake;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isRealBlur = !_fake && tier != GlassTier.low;

    // Blur follows the device tier only. Toggling it for a resize rebuilt
    // every glass surface twice and visibly changed the chrome colour.
    final blurActive = isRealBlur;

    // Dark obsidian glass for floating bars/sheets vs subtle surface tint for list cards
    final decoration = BoxDecoration(
      borderRadius: radius,
      color: isRealBlur
          ? AppColors.glassStrong
          : AppColors.bgElevated.withValues(alpha: 0.72),
      border: Border.all(
        color: isRealBlur ? const Color(0x1FFFFFFF) : AppColors.glassBorder,
        width: 0.6,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isRealBlur
            ? const [Color(0x14FFFFFF), Color(0x03FFFFFF)]
            : const [Color(0x0DFFFFFF), Color(0x02FFFFFF)],
      ),
      boxShadow: isRealBlur
          ? const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ]
          : null,
    );

    final inner = Container(
      padding: padding,
      decoration: decoration,
      child: Material(type: MaterialType.transparency, child: child),
    );

    Widget surface;
    if (!blurActive) {
      surface = ClipRRect(borderRadius: radius, child: inner);
    } else {
      final clampedSigma = sigma.clamp(16.0, 32.0);
      surface = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          // Grouped when an ancestor `BackdropGroup` exists (the chrome bars),
          // so overlapping/adjacent glass is blurred in one engine pass. It
          // behaves exactly like a plain BackdropFilter elsewhere.
          child: BackdropFilter.grouped(
            filter: ImageFilter.blur(
              sigmaX: clampedSigma,
              sigmaY: clampedSigma,
            ),
            child: inner,
          ),
        ),
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: surface);
    }
    return surface;
  }
}
