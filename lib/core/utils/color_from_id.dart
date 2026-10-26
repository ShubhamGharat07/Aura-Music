import 'package:flutter/material.dart';

// Track accent: Phase-0 derives a deterministic colour from the track id
// (clamped S/L per PRD 8.2). The album-art palette pipeline (F06) replaces
// this by pushing into ThemeCubit in Phase 1.

/// Returns an accent colour for [id] clamped to the design range.
Color accentFromId(
  String id, {
  double saturation = 0.62,
  double lightness = 0.62,
}) {
  final hash = id.codeUnits.fold<int>(
    0,
    (acc, unit) => (acc * 31 + unit) & 0x7fffffff,
  );
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}
