import 'package:equatable/equatable.dart';

import 'package:aura_music/features/downloads/domain/entities/download.dart';

/// Aggregated download stats for the Storage settings screen.

/// Download totals (pure Dart, unit-testable).
final class DownloadSummary extends Equatable {
  /// Creates a summary.
  const DownloadSummary({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.failed,
    required this.bytesUsed,
  });

  /// Aggregates [downloads] into a summary.
  factory DownloadSummary.of(Iterable<Download> downloads) {
    var total = 0, completed = 0, inProgress = 0, failed = 0, bytes = 0;
    for (final download in downloads) {
      total++;
      switch (download.status) {
        case DownloadStatus.completed:
          completed++;
          bytes += download.bytesDownloaded;
        case DownloadStatus.failed:
          failed++;
        case DownloadStatus.queued:
        case DownloadStatus.downloading:
        case DownloadStatus.paused:
          inProgress++;
      }
    }
    return DownloadSummary(
      total: total,
      completed: completed,
      inProgress: inProgress,
      failed: failed,
      bytesUsed: bytes,
    );
  }

  /// All rows.
  final int total;

  /// Fully downloaded rows.
  final int completed;

  /// In-flight rows.
  final int inProgress;

  /// Failed rows.
  final int failed;

  /// Bytes used by completed downloads.
  final int bytesUsed;

  @override
  List<Object?> get props => [total, completed, inProgress, failed, bytesUsed];
}
