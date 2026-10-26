import 'package:equatable/equatable.dart';

/// Domain-layer failures. Data layer maps [AppException] to these;
/// BLoC maps these to state; UI maps state to a localised message.
///
/// Pure Dart: no dependency on `dio`, `drift` or Flutter.

/// Base failure (sealed: exhaustive `switch` in BLoCs).
sealed class Failure extends Equatable {
  /// Creates a failure with a user-facing message key.
  const Failure(this.message);

  /// Localised message (or message key for ARB lookup).
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Remote call failed.
final class ServerFailure extends Failure {
  /// Creates a server failure.
  const ServerFailure(super.message);
}

/// Device is offline.
final class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure(super.message);
}

/// Local cache / database failure.
final class CacheFailure extends Failure {
  /// Creates a cache failure.
  const CacheFailure(super.message);
}

/// All stream sources in the fallback chain failed.
final class StreamFailure extends Failure {
  /// Creates a stream failure.
  const StreamFailure(super.message);
}

/// Permission denied.
final class PermissionFailure extends Failure {
  /// Creates a permission failure.
  const PermissionFailure(super.message);
}

/// Anything else.
final class UnknownFailure extends Failure {
  /// Creates an unknown failure.
  const UnknownFailure(super.message);
}
