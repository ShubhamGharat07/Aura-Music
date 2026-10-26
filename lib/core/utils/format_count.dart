// Compact number formatting for UI counters (plays, followers).

/// Formats a count compactly: `999`, `12.5k`, `833k`, `6.7M`, `1.2B`.
String formatCompactCount(int value) {
  if (value < 1000) return '$value';
  const units = <(int, String)>[(1000000000, 'B'), (1000000, 'M'), (1000, 'k')];
  for (final (threshold, suffix) in units) {
    if (value < threshold) continue;
    final scaled = value / threshold;
    final whole = scaled >= 100 || scaled == scaled.roundToDouble();
    return '${scaled.toStringAsFixed(whole ? 0 : 1)}$suffix';
  }
  return '$value';
}
