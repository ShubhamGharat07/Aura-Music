import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Extracts a track accent from album artwork and clamps it to the design
/// range (PRD F06 / 8.2): hue is kept, saturation lands in 45-75% and
/// lightness in 55-70%, so text and icons stay readable on every artwork.
///
/// Results are cached with a TTL + LRU cap: the same cover scrolled back into
/// view costs zero decode work, and a long session cannot grow the map
/// unbounded.
final class DynamicAccentService {
  /// Creates the service.
  DynamicAccentService({
    this.maxEntries = 24,
    this.ttl = const Duration(minutes: 45),
  });

  /// Maximum cached covers.
  final int maxEntries;

  /// How long an extracted accent stays valid.
  final Duration ttl;

  final LinkedHashMap<String, _CachedAccent> _cache =
      LinkedHashMap<String, _CachedAccent>();

  /// Resolves the clamped accent for [artUrl], or null when the image cannot
  /// be decoded (network failure, empty artwork). Failures are not cached.
  Future<Color?> accentFor(String artUrl) async {
    final now = DateTime.now();
    final cached = _cache.remove(artUrl);
    if (cached != null && now.difference(cached.at) < ttl) {
      _cache[artUrl] = cached;
      return cached.color;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(NetworkImage(artUrl), width: 96),
        size: const Size(96, 96),
        maximumColorCount: 12,
      );
      final swatch =
          palette.darkVibrantColor ??
          palette.vibrantColor ??
          palette.mutedColor ??
          palette.dominantColor;
      if (swatch == null) return null;
      final color = clampAccent(swatch.color);
      _store(artUrl, color, now);
      return color;
    } on Object {
      return null;
    }
  }

  /// Drops every cached accent (Settings → Appearance toggle off / tests).
  void clear() => _cache.clear();

  /// Clamps [color] into the readable accent window.
  static Color clampAccent(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(hsl.saturation.clamp(0.45, 0.75).toDouble())
        .withLightness(hsl.lightness.clamp(0.55, 0.70).toDouble())
        .toColor();
  }

  void _store(String artUrl, Color color, DateTime at) {
    _cache[artUrl] = _CachedAccent(color, at);
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

final class _CachedAccent {
  const _CachedAccent(this.color, this.at);

  final Color color;
  final DateTime at;
}
