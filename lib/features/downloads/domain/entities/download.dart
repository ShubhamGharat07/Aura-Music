import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// Lifecycle of a downloaded track (persisted as an int ordinal).

/// Download lifecycle status.
enum DownloadStatus {
  /// Waiting to start.
  queued,

  /// Bytes are being fetched.
  downloading,

  /// Interrupted; resumable.
  paused,

  /// Fully downloaded and available offline.
  completed,

  /// Download failed (see [Download.error]).
  failed,
}

/// A user-managed offline track (PRD S14). Denormalises the [track] snapshot
/// so a row stays self-sufficient when the device is offline.
final class Download extends Equatable {
  /// Creates a download record.
  const Download({
    required this.track,
    required this.status,
    this.filePath,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.error,
  });

  /// Track metadata snapshot.
  final Track track;

  /// Current status.
  final DownloadStatus status;

  /// Absolute path to the local audio file (when [isComplete]).
  final String? filePath;

  /// Bytes written so far.
  final int bytesDownloaded;

  /// Total bytes (0 until the server reports a length).
  final int totalBytes;

  /// Error message when [status] is [DownloadStatus.failed].
  final String? error;

  /// Whether the file is present and playable offline.
  bool get isComplete => status == DownloadStatus.completed && filePath != null;

  /// Whether the download is still work-in-progress.
  bool get isActive =>
      status == DownloadStatus.queued ||
      status == DownloadStatus.downloading ||
      status == DownloadStatus.paused;

  /// Fraction played back as (0..1) for progress UIs.
  double get progress {
    if (status == DownloadStatus.completed) return 1;
    if (totalBytes <= 0) return 0;
    return (bytesDownloaded / totalBytes).clamp(0.0, 1.0);
  }

  /// Copies with overrides.
  Download copyWith({
    DownloadStatus? status,
    String? filePath,
    int? bytesDownloaded,
    int? totalBytes,
    String? error,
    bool clearError = false,
  }) => Download(
    track: track,
    status: status ?? this.status,
    filePath: filePath ?? this.filePath,
    bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
    totalBytes: totalBytes ?? this.totalBytes,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    track,
    status,
    filePath,
    bytesDownloaded,
    totalBytes,
    error,
  ];
}
