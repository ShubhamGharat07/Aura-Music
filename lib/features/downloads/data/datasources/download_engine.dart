import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:aura_music/core/error/exceptions.dart';

/// A progress tick emitted while streaming a download.

/// Download progress tick.
final class DownloadChunk {
  /// Creates a tick.
  const DownloadChunk({
    required this.received,
    required this.total,
    required this.path,
  });

  /// Bytes written so far.
  final int received;

  /// Expected total bytes (0 when unknown).
  final int total;

  /// Destination path of the completed file.
  final String path;
}

/// Streams remote audio to local storage (data layer only).
abstract interface class DownloadEngine {
  /// Absolute destination path for [fileName].
  Future<String> pathFor(String fileName);

  /// Streams [url] into [fileName], yielding progress until complete.
  ///
  /// [cancelToken] aborts an in-flight transfer (pause / delete); the partial
  /// `.part` file is kept so a later resume continues with an HTTP `Range`.
  Stream<DownloadChunk> download({
    required String url,
    required String fileName,
    CancelToken? cancelToken,
  });
}

/// Dio-backed engine writing to an app-private `downloads/` directory,
/// resuming interrupted transfers with an HTTP `Range` request (PRD S14).
final class DioDownloadEngine implements DownloadEngine {
  /// Creates the engine (a custom [directory] is used by tests).
  DioDownloadEngine(this._dio, {Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  final Dio _dio;
  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'downloads'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> pathFor(String fileName) async {
    final dir = await _directory();
    return p.join(dir.path, fileName);
  }

  @override
  Stream<DownloadChunk> download({
    required String url,
    required String fileName,
    CancelToken? cancelToken,
  }) async* {
    final targetPath = await pathFor(fileName);
    final target = File(targetPath);
    final part = File('$targetPath.part');
    final resumeAt = part.existsSync() ? part.lengthSync() : 0;

    final ResponseBody body;
    final bool resumable;
    final int total;
    try {
      final response = await _dio.get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: resumeAt > 0
              ? {HttpHeaders.rangeHeader: 'bytes=$resumeAt-'}
              : null,
        ),
      );
      final data = response.data;
      if (data == null) throw const ServerException('Empty download response');
      body = data;
      resumable =
          response.statusCode == HttpStatus.partialContent && resumeAt > 0;
      final length =
          int.tryParse(
            response.headers.value(Headers.contentLengthHeader) ?? '',
          ) ??
          0;
      total = resumable ? resumeAt + length : length;
    } on DioException catch (error) {
      throw _mapError(error);
    }

    var received = resumable ? resumeAt : 0;
    final sink = part.openWrite(
      mode: resumable ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield DownloadChunk(received: received, total: total, path: targetPath);
      }
      await sink.flush();
    } on DioException catch (error) {
      await sink.close();
      throw _mapError(error);
    } catch (error) {
      await sink.close();
      throw NetworkException('$error');
    }
    await sink.close();
    if (target.existsSync()) await target.delete();
    await part.rename(targetPath);
  }

  AppException _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return NetworkException(error.message ?? 'Network unavailable');
      case DioExceptionType.badResponse:
      case DioExceptionType.transformTimeout:
        return ServerException(
          error.message ?? 'Server error',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const DownloadCancelledException();
      case DioExceptionType.badCertificate:
        return ServerException(error.message ?? 'Request failed');
    }
  }
}
