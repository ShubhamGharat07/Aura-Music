import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

/// Caps how many requests are in flight at once.
///
/// The home feed asks for six or seven catalog calls "at the same time"; the
/// public catalog throttles bursts, so a few of them used to answer late (or
/// with 429) and the UI looked broken. It also keeps the responses from all
/// landing inside the same frame, which is what made the first Home paint
/// stutter. Calls wait their turn instead of failing.
final class ConcurrencyInterceptor extends Interceptor {
  /// Creates a limiter allowing [maxConcurrent] simultaneous requests.
  ConcurrencyInterceptor({this.maxConcurrent = 3});

  /// How many requests may be in flight at once.
  final int maxConcurrent;

  /// Marks a request that already holds a slot (retries).
  static const String _slotKey = 'aura_concurrency_slot';

  final Queue<Completer<void>> _queue = Queue<Completer<void>>();
  int _active = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_slotKey] == true) {
      handler.next(options);
      return;
    }
    await _acquire();
    options.extra[_slotKey] = true;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _release(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release(err.requestOptions);
    handler.next(err);
  }

  Future<void> _acquire() {
    if (_active < maxConcurrent) {
      _active++;
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void _release(RequestOptions options) {
    if (options.extra.remove(_slotKey) != true) return;
    if (_queue.isEmpty) {
      _active--;
      return;
    }
    _queue.removeFirst().complete();
  }
}
