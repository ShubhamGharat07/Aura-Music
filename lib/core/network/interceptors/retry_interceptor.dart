import 'package:dio/dio.dart';

/// Retries idempotent GET requests once on 429 / 5xx.

/// Simple single-retry interceptor for transient failures.
final class RetryInterceptor extends Interceptor {
  /// Creates a retry interceptor.
  RetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;
    final isGet = err.requestOptions.method.toUpperCase() == 'GET';
    final retried = err.requestOptions.extra['retried'] == true;
    if (!isGet ||
        retried ||
        (status != 429 && (status < 500 || status >= 600))) {
      handler.next(err);
      return;
    }
    try {
      final options = err.requestOptions..extra['retried'] = true;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (_) {
      handler.next(err);
    }
  }
}
