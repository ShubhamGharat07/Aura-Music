import 'package:dio/dio.dart';

import 'package:aura_music/core/error/exceptions.dart';

/// LRCLIB client (data layer only). `GET /api/get` returns synced + plain
/// lyrics; a 404 means "no lyrics" (not an error).

/// Raw LRCLIB payload (subsets of the API response).
final class LrclibPayload {
  /// Creates a payload.
  const LrclibPayload({this.syncedLyrics, this.plainLyrics});

  /// LRC-format synced lyrics, if present.
  final String? syncedLyrics;

  /// Unsynced plain lyrics, if present.
  final String? plainLyrics;
}

/// Thin wrapper over the LRCLIB REST API.
final class LrclibRemoteDataSource {
  /// Creates the data source.
  const LrclibRemoteDataSource(this._dio);

  final Dio _dio;

  /// Fetches lyrics for a track, or null when the API returns 404.
  Future<LrclibPayload?> fetch({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/get',
        queryParameters: {
          'track_name': trackName,
          'artist_name': artistName,
          if (albumName != null && albumName.isNotEmpty)
            'album_name': albumName,
          if (durationSeconds != null && durationSeconds > 0)
            'duration': durationSeconds,
        },
      );
      final data = response.data ?? const {};
      return LrclibPayload(
        syncedLyrics: data['syncedLyrics'] as String?,
        plainLyrics: data['plainLyrics'] as String?,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _mapError(error);
    }
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
