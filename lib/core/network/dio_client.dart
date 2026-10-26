import 'package:dio/dio.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/network/interceptors/concurrency_interceptor.dart';
import 'package:aura_music/core/network/interceptors/retry_interceptor.dart';

/// Dio factory (data layer only). Presentation/domain must never import `dio`.
///
/// Includes 10 s / 20 s timeouts (PRD 9.10), a single retry for idempotent
/// GETs on 429 / 5xx, and a limit on how many requests run at once so a page
/// that fires six catalog calls does not get throttled or stutter.

/// Creates a hardened [Dio] client for one base URL.
Dio createDioClient({required String baseUrl, bool longTimeouts = false}) {
  final timeout = longTimeouts
      ? AppConstants.longTimeout
      : AppConstants.shortTimeout;
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.shortTimeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: const {'Accept': 'application/json'},
    ),
  );
  // Order matters: error handlers run in reverse, so the concurrency slot is
  // released before the retry interceptor re-fires the request.
  dio.interceptors.addAll([RetryInterceptor(dio), ConcurrencyInterceptor()]);
  return dio;
}

/// Creates a [Dio] tuned for large streamed downloads: redirects are followed
/// (CDN 302 -> signed media URL) and no receive timeout aborts a long transfer.
Dio createDownloadDio() => Dio(
  BaseOptions(
    connectTimeout: AppConstants.shortTimeout,
    followRedirects: true,
    headers: const {'Accept': '*/*'},
  ),
);
