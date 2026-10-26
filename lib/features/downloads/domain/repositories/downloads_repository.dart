import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Persistent, user-managed offline downloads (PRD S14).
/// Data layer keeps the Drift rows and local files behind this contract.
abstract interface class DownloadsRepository {
  /// Emits the full download list on every change (progress included).
  Stream<List<Download>> watchAll();

  /// Current download list snapshot.
  Future<List<Download>> all();

  /// Queues [track] for offline playback. At most three transfers run in
  /// parallel; the rest wait as [DownloadStatus.queued]. Resolves once this
  /// transfer leaves the active queue (completed, paused or failed).
  Future<Either<Failure, Unit>> enqueue(Track track);

  /// Pauses an active transfer (or a queued one) keeping the partial file.
  Future<Either<Failure, Unit>> pause(String trackId);

  /// Resumes a paused transfer from the byte offset already on disk.
  Future<Either<Failure, Unit>> resume(String trackId);

  /// Retries a failed transfer (same resume semantics, fresh attempt).
  Future<Either<Failure, Unit>> retry(String trackId);

  /// Deletes the download row and its file for [trackId], aborting any
  /// in-flight transfer first.
  Future<Either<Failure, Unit>> remove(String trackId);

  /// Local file path for a completed download, or null when absent.
  Future<Either<Failure, String?>> localFileFor(String trackId);
}
