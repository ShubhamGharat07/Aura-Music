import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/downloads/domain/usecases/download_track.dart';
import 'package:aura_music/features/downloads/domain/usecases/pause_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/remove_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/resume_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/retry_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/watch_downloads.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

/// Downloads screen status.

/// Downloads list status.
enum DownloadsStatus {
  /// Waiting for the first emission.
  loading,

  /// At least one download exists.
  ready,

  /// No downloads yet.
  empty,

  /// A download action failed.
  error,
}

/// Immutable downloads state.
final class DownloadsState extends Equatable {
  /// Creates the state.
  const DownloadsState({
    this.status = DownloadsStatus.loading,
    this.downloads = const [],
    this.error,
  });

  /// Current status.
  final DownloadsStatus status;

  /// Current downloads (newest first).
  final List<Download> downloads;

  /// Error message (when [status] is [DownloadsStatus.error]).
  final String? error;

  /// Copies with overrides.
  DownloadsState copyWith({
    DownloadsStatus? status,
    List<Download>? downloads,
    String? error,
  }) => DownloadsState(
    status: status ?? this.status,
    downloads: downloads ?? this.downloads,
    error: error,
  );

  @override
  List<Object?> get props => [status, downloads, error];
}

/// Drives the Downloads screen: streams the list, enqueues and removes.
final class DownloadsCubit extends Cubit<DownloadsState> {
  /// Creates the cubit and subscribes to the download stream.
  DownloadsCubit(
    this._watch,
    this._download,
    this._remove,
    this._pause,
    this._resume,
    this._retry, {
    ResolveStream? resolveStream,
  }) : _resolveStream = resolveStream,
       super(const DownloadsState()) {
    _sub = _watch().listen(
      _onList,
      onError: (Object error) =>
          emit(DownloadsState(status: DownloadsStatus.error, error: '$error')),
    );
  }

  final WatchDownloads _watch;
  final DownloadTrack _download;
  final RemoveDownload _remove;
  final PauseDownload _pause;
  final ResumeDownload _resume;
  final RetryDownload _retry;
  final ResolveStream? _resolveStream;
  late final StreamSubscription<List<Download>> _sub;

  /// Tracks paused by [onConnectivityChanged] only, so reconnecting never
  /// resumes something the user paused deliberately.
  final Set<String> _pausedByNetwork = {};

  void _onList(List<Download> downloads) => emit(
    DownloadsState(
      status: downloads.isEmpty ? DownloadsStatus.empty : DownloadsStatus.ready,
      downloads: downloads,
    ),
  );

  /// Downloads [track]; progress arrives through the watched list. The stream
  /// URL is refreshed first: catalog URLs expire, and downloading with a stale
  /// one is the usual cause of an immediate "failed" row.
  Future<void> download(Track track) async {
    var target = track;
    final resolver = _resolveStream;
    if (resolver != null) {
      final result = await resolver(track);
      target = result.fold(
        (_) => track,
        (url) => track.copyWith(streamUrl: url),
      );
    }
    await _run(_download(target));
  }

  /// Pauses [trackId], keeping the partial file for a later resume.
  Future<void> pause(String trackId) {
    _pausedByNetwork.remove(trackId);
    return _run(_pause(trackId));
  }

  /// Resumes [trackId] from the byte offset already on disk.
  Future<void> resume(String trackId) {
    _pausedByNetwork.remove(trackId);
    return _run(_resume(trackId));
  }

  /// Retries a failed download for [trackId].
  Future<void> retry(String trackId) {
    _pausedByNetwork.remove(trackId);
    return _run(_retry(trackId));
  }

  /// Removes the download (and file) for [trackId].
  Future<void> remove(String trackId) {
    _pausedByNetwork.remove(trackId);
    return _remove(trackId);
  }

  /// Reacts to connectivity changes: pauses active work while offline and
  /// auto-resumes only that work when the connection returns.
  Future<void> onConnectivityChanged(bool online) async {
    if (isClosed) return;
    if (!online) {
      final active = state.downloads
          .where(
            (download) =>
                download.status == DownloadStatus.downloading ||
                download.status == DownloadStatus.queued,
          )
          .map((download) => download.track.id)
          .toList(growable: false);
      for (final id in active) {
        // Register first so a manual pause/resume during the await wins.
        _pausedByNetwork.add(id);
        if (!await _apply(_pause(id))) _pausedByNetwork.remove(id);
      }
      return;
    }

    final paused = _pausedByNetwork.toList(growable: false);
    _pausedByNetwork.clear();
    if (paused.isEmpty) return;
    final known = state.downloads.map((download) => download.track.id).toSet();
    for (final id in paused) {
      if (known.contains(id)) await _apply(_resume(id));
    }
  }

  Future<void> _run(Future<Either<Failure, Unit>> action) async {
    await _apply(action);
  }

  Future<bool> _apply(Future<Either<Failure, Unit>> action) async {
    final result = await action;
    if (isClosed) return false;
    return result.fold((failure) {
      emit(
        state.copyWith(status: DownloadsStatus.error, error: failure.message),
      );
      return false;
    }, (_) => true);
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
