import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/network/interceptors/retry_interceptor.dart';

final class _MockDio extends Mock implements Dio {}

final class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late _MockDio dio;
  late _MockErrorHandler handler;
  late RetryInterceptor interceptor;

  RequestOptions options(String method, {bool retried = false}) =>
      RequestOptions(
        path: '/x',
        method: method,
        extra: retried ? {'retried': true} : {},
      );

  DioException failure(RequestOptions opts, int status) => DioException(
    requestOptions: opts,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: opts, statusCode: status),
  );

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/x'));
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/x')),
    );
    registerFallbackValue(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.unknown,
      ),
    );
  });

  setUp(() {
    dio = _MockDio();
    handler = _MockErrorHandler();
    interceptor = RetryInterceptor(dio);
  });

  test('retries a GET on 5xx and resolves with the retried response', () async {
    when(() => dio.fetch<dynamic>(any())).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
      ),
    );

    await interceptor.onError(failure(options('GET'), 503), handler);

    verify(() => handler.resolve(any())).called(1);
    verifyNever(() => handler.next(any()));
  });

  test('retries a GET on 429', () async {
    when(() => dio.fetch<dynamic>(any())).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
      ),
    );

    await interceptor.onError(failure(options('GET'), 429), handler);

    verify(() => handler.resolve(any())).called(1);
  });

  test('does not retry non-idempotent verbs', () async {
    await interceptor.onError(failure(options('POST'), 500), handler);

    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(any())).called(1);
  });

  test('does not retry client errors', () async {
    await interceptor.onError(failure(options('GET'), 400), handler);

    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(any())).called(1);
  });

  test('does not retry a request that already retried', () async {
    await interceptor.onError(
      failure(options('GET', retried: true), 500),
      handler,
    );

    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(any())).called(1);
  });

  test('surfaces the original error when the retry fails', () async {
    when(() => dio.fetch<dynamic>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    );

    await interceptor.onError(failure(options('GET'), 500), handler);

    verifyNever(() => handler.resolve(any()));
    verify(() => handler.next(any())).called(1);
  });
}
