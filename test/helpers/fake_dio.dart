import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Test helper: a [Dio] whose transport is a [FakeHttpAdapter], so data-layer
/// mapping and error handling can be exercised without a real network.

/// Adapter that returns / throws whatever [handler] decides.
final class FakeHttpAdapter implements HttpClientAdapter {
  /// Creates the adapter.
  FakeHttpAdapter(this.handler);

  /// Per-request handler.
  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Every request the client issued, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a JSON [ResponseBody], optionally under a custom content-type (so
/// tests can reproduce servers that mislabel JSON as `text/html`).
ResponseBody jsonResponse(
  Object body, {
  int status = 200,
  String contentType = Headers.jsonContentType,
}) => ResponseBody.fromString(
  body is String ? body : jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [contentType],
  },
);

/// Wraps [adapter] in a [Dio] pointed at [baseUrl].
Dio dioWithAdapter(FakeHttpAdapter adapter, {required String baseUrl}) =>
    Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
