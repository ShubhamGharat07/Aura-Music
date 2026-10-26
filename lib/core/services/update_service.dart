import 'package:dio/dio.dart';

import 'package:aura_music/core/constants/app_constants.dart';

/// Update manifest published by the release pipeline (PRD F15).

/// Parsed update manifest.
final class UpdateInfo {
  /// Creates update info.
  const UpdateInfo({required this.version, this.downloadUrl, this.notes});

  /// Latest published version.
  final String version;

  /// Direct download / store URL.
  final String? downloadUrl;

  /// Release notes.
  final String? notes;
}

/// Reads the update manifest. Returns null when this build has no channel
/// configured or the server cannot be reached, so the UI can stay truthful.
final class UpdateService {
  /// Creates the service.
  const UpdateService(this._dio);

  final Dio _dio;

  /// Fetches the latest manifest, or null.
  Future<UpdateInfo?> check() async {
    final url = AppConstants.updateManifestUrl;
    if (url.isEmpty) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: AppConstants.shortTimeout,
          receiveTimeout: AppConstants.shortTimeout,
        ),
      );
      final data = response.data;
      final version = data?['version'];
      if (version is! String || version.isEmpty) return null;
      return UpdateInfo(
        version: version,
        downloadUrl: data?['download_url'] as String?,
        notes: data?['notes'] as String?,
      );
    } on Object {
      return null;
    }
  }
}
