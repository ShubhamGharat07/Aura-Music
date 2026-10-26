import 'package:dio/dio.dart';

import 'package:aura_music/core/error/exceptions.dart';

/// Unison lyrics client (data layer only). A crowdsourced fallback for LRCLIB.
///
/// `GET /lyrics` returns the single best match; a miss (`success:false` or an
/// empty body) is reported as null, not an error.

/// Raw Unison payload: the lyrics body plus its declared `format`
/// (`lrc`, `ttml`/`richsync`, …), so the caller picks the right parser.
final class UnisonPayload {
  /// Creates a payload.
  const UnisonPayload({required this.lyrics, this.format});

  /// Lyrics body (LRC text or a TTML document).
  final String lyrics;

  /// Provider-declared format, lowercase when present.
  final String? format;
}

/// Thin wrapper over the Unison lyrics API (`https://unison.boidu.dev`).
final class UnisonRemoteDataSource {
  /// Creates the data source.
  const UnisonRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetches the best-matching lyrics, or null when none exist.
  Future<UnisonPayload?> fetch({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/lyrics',
        queryParameters: <String, dynamic>{
          'song': title,
          'artist': artist,
          if (album != null && album.isNotEmpty) 'album': album,
          if (durationSeconds != null && durationSeconds > 0)
            'duration': durationSeconds,
        },
      );
      return _extract(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _mapError(error);
    }
  }

  UnisonPayload? _extract(Map<String, dynamic>? body) {
    if (body == null || body['success'] != true) return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;
    final lyrics = data['lyrics'] as String?;
    if (lyrics == null || lyrics.trim().isEmpty) return null;
    final format = data['format'] as String?;
    return UnisonPayload(lyrics: lyrics, format: format?.toLowerCase());
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
      case DioExceptionType.badCertificate:
        return ServerException(error.message ?? 'Request failed');
    }
  }
}
