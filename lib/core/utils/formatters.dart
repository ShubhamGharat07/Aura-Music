/// Duration / number / byte formatting helpers (PRD 5.3: no magic numbers,
/// shared formatters). Pure Dart: unit-testable.
library;

/// Formats a [Duration] as `m:ss` or `h:mm:ss`.
String formatDuration(Duration d) {
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final minutes = d.inMinutes.remainder(60);
  if (d.inHours > 0) {
    return '${d.inHours}:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// Formats a byte count as `MB` / `GB` for the storage bars (PRD S19).
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(0)} MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
  return '$bytes B';
}

/// Compact count like `1.2K` for song/play counts.
String formatCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}
