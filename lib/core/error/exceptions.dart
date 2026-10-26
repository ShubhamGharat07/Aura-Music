// Data-layer exceptions. Caught at repository boundary and mapped to
// [Failure] subtypes. Never leak outside `data/`.

/// Base for all data-layer exceptions.
sealed class AppException implements Exception {
  /// Creates an app exception with a debug-only message.
  const AppException(this.message);

  /// Debug message (never shown raw in UI).
  final String message;
}

/// Remote call failed (5xx, malformed payload, timeout mapped here).
final class ServerException extends AppException {
  /// Creates a server exception.
  const ServerException(super.message, {this.statusCode});

  /// HTTP status when available.
  final int? statusCode;
}

/// No connectivity or DNS failure.
final class NetworkException extends AppException {
  /// Creates a network exception.
  const NetworkException(super.message);
}

/// Local cache / database failure.
final class CacheException extends AppException {
  /// Creates a cache exception.
  const CacheException(super.message);
}

/// Stream URL extraction failed for one source.
final class StreamResolveException extends AppException {
  /// Creates a stream-resolve exception.
  const StreamResolveException(super.message, {required this.source});

  /// Source that failed (e.g. `youtube`, `innertube`).
  final String source;
}

/// Transfer cancelled on purpose (pause / delete), not a failure.
final class DownloadCancelledException extends AppException {
  /// Creates a cancellation marker.
  const DownloadCancelledException([super.message = 'Download cancelled']);
}

/// Missing permission (storage, notifications, install packages).
final class PermissionException extends AppException {
  /// Creates a permission exception.
  const PermissionException(super.message);
}
