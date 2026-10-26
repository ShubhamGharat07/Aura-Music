import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/exceptions.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/downloads_dao.dart';
import 'package:aura_music/features/downloads/data/datasources/download_engine.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Drift + file-backed downloads repository with a bounded transfer queue
/// (PRD S14): at most [maxConcurrent] streams run at once, and each transfer
/// can be paused, resumed, retried or cancelled without losing its `.part`
/// file.
final class DownloadsRepositoryImpl implements DownloadsRepository {
  /// Creates the repository.
  DownloadsRepositoryImpl(this._dao, this._engine, {this.maxConcurrent = 3});

  final DownloadsDao _dao;
  final DownloadEngine _engine;

  /// Parallel transfer cap.
  final int maxConcurrent;

  static const int _flushEvery = 256 * 1024;

  final Map<String, CancelToken> _tokens = <String, CancelToken>{};
  final Set<String> _paused = <String>{};
  final Set<String> _cancelled = <String>{};
  final List<Completer<void>> _waiters = <Completer<void>>[];
  int _active = 0;

  @override
  Stream<List<Download>> watchAll() => _dao.watchAll().map(
    (rows) => rows.map(_toEntity).toList(growable: false),
  );

  @override
  Future<List<Download>> all() async =>
      (await _dao.all()).map(_toEntity).toList(growable: false);

  @override
  Future<Either<Failure, Unit>> enqueue(Track track) async {
    final url = track.streamUrl;
    if (url == null || url.isEmpty) {
      await _dao.create(_create(track));
      await _dao.patch(
        track.id,
        _status(DownloadStatus.failed, error: 'No stream URL'),
      );
      return const Left(UnknownFailure('No stream URL'));
    }
    _paused.remove(track.id);
    _cancelled.remove(track.id);
    if (await _dao.byTrack(track.id) == null) {
      await _dao.create(_create(track));
    } else {
      await _dao.patch(track.id, _status(DownloadStatus.queued));
    }
    await _acquire();
    final token = CancelToken();
    _tokens[track.id] = token;
    try {
      if (_cancelled.contains(track.id)) return const Right(unit);
      if (_paused.contains(track.id)) {
        await _dao.patch(track.id, _status(DownloadStatus.paused));
        return const Right(unit);
      }
      await _dao.patch(track.id, _status(DownloadStatus.downloading));
      final fileName = _fileName(track);
      final path = await _engine.pathFor(fileName);
      var lastFlush = 0;
      var total = 0;
      await for (final chunk in _engine.download(
        url: url,
        fileName: fileName,
        cancelToken: token,
      )) {
        total = chunk.total;
        final due =
            chunk.received - lastFlush >= _flushEvery ||
            (chunk.total > 0 && chunk.received >= chunk.total);
        if (due) {
          lastFlush = chunk.received;
          await _dao.patch(
            track.id,
            _progress(chunk.received, chunk.total, path),
          );
        }
      }
      if (_cancelled.contains(track.id)) return const Right(unit);
      if (_paused.contains(track.id)) {
        await _dao.patch(track.id, _status(DownloadStatus.paused));
        return const Right(unit);
      }
      await _dao.patch(
        track.id,
        _completed(path, total > 0 ? total : lastFlush),
      );
      return const Right(unit);
    } on DownloadCancelledException {
      // Pause / delete already persisted the target status.
      return const Right(unit);
    } on AppException catch (error) {
      await _dao.patch(
        track.id,
        _status(DownloadStatus.failed, error: error.message),
      );
      return Left(_failure(error));
    } catch (error) {
      await _dao.patch(
        track.id,
        _status(DownloadStatus.failed, error: '$error'),
      );
      return Left(UnknownFailure('$error'));
    } finally {
      _tokens.remove(track.id);
      _paused.remove(track.id);
      _cancelled.remove(track.id);
      _release();
    }
  }

  @override
  Future<Either<Failure, Unit>> pause(String trackId) async {
    final row = await _dao.byTrack(trackId);
    if (row == null || row.status == DownloadStatus.completed) {
      return const Right(unit);
    }
    _paused.add(trackId);
    await _dao.patch(trackId, _status(DownloadStatus.paused));
    _tokens[trackId]?.cancel('paused');
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resume(String trackId) async {
    final row = await _dao.byTrack(trackId);
    if (row == null) {
      return const Left(UnknownFailure('Download not found'));
    }
    _paused.remove(trackId);
    return enqueue(_toEntity(row).track);
  }

  @override
  Future<Either<Failure, Unit>> retry(String trackId) => resume(trackId);

  @override
  Future<Either<Failure, Unit>> remove(String trackId) async {
    try {
      final row = await _dao.byTrack(trackId);
      final active =
          row != null &&
          (row.status == DownloadStatus.queued ||
              row.status == DownloadStatus.downloading);
      if (active) {
        _cancelled.add(trackId);
        _tokens[trackId]?.cancel('removed');
      }
      await _dao.delete(trackId);
      final path = row?.filePath;
      if (path != null) {
        final file = File(path);
        if (file.existsSync()) await file.delete();
        final part = File('$path.part');
        if (part.existsSync()) await part.delete();
      }
      return const Right(unit);
    } on FileSystemException catch (error) {
      return Left(CacheFailure(error.message));
    }
  }

  @override
  Future<Either<Failure, String?>> localFileFor(String trackId) async {
    try {
      final row = await _dao.byTrack(trackId);
      final path = row?.filePath;
      if (row == null ||
          row.status != DownloadStatus.completed ||
          path == null) {
        return const Right(null);
      }
      if (!File(path).existsSync()) return const Right(null);
      return Right(path);
    } catch (error) {
      return Left(CacheFailure('$error'));
    }
  }

  Future<void> _acquire() async {
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _active--;
    }
  }

  Download _toEntity(DownloadEntry row) => Download(
    track: Track(
      id: row.trackId,
      title: row.title,
      artist: row.artist,
      album: row.album,
      artUrl: row.artUrl,
      duration: Duration(milliseconds: row.durationMs),
    ),
    status: row.status,
    filePath: row.filePath,
    bytesDownloaded: row.bytesDownloaded,
    totalBytes: row.totalBytes,
    error: row.error,
  );

  DownloadEntriesCompanion _create(Track track) =>
      DownloadEntriesCompanion.insert(
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        album: Value(track.album),
        artUrl: Value(track.artUrl),
        durationMs: Value(track.duration.inMilliseconds),
        status: DownloadStatus.queued,
        createdAt: DateTime.now(),
      );

  DownloadEntriesCompanion _progress(int received, int total, String path) =>
      DownloadEntriesCompanion(
        status: const Value(DownloadStatus.downloading),
        filePath: Value(path),
        bytesDownloaded: Value(received),
        totalBytes: Value(total),
      );

  DownloadEntriesCompanion _completed(String path, int total) =>
      DownloadEntriesCompanion(
        status: const Value(DownloadStatus.completed),
        filePath: Value(path),
        bytesDownloaded: Value(total),
        totalBytes: Value(total),
        completedAt: Value(DateTime.now()),
        error: const Value(null),
      );

  DownloadEntriesCompanion _status(DownloadStatus status, {String? error}) =>
      DownloadEntriesCompanion(status: Value(status), error: Value(error));

  String _fileName(Track track) =>
      '${track.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.mp3';

  Failure _failure(AppException error) {
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    if (error is CacheException) return CacheFailure(error.message);
    return UnknownFailure(error.message);
  }
}
