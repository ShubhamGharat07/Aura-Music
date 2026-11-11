/// User-facing error copy for the data layer.
///
/// Raw transport messages (Dio's `error.message`, socket/DNS text) are never
/// surfaced: data sources map them to these strings so the UI can show a
/// friendly line next to its Retry action.
abstract final class ErrorMessages {
  /// No connection or DNS failure.
  static const String offline =
      "You're offline. Check your internet connection and try again.";

  /// The request took too long.
  static const String timeout = 'The connection timed out. Please try again.';

  /// The server answered with an error.
  static const String server =
      'Something went wrong on our end. Please try again.';

  /// Any other transport failure.
  static const String generic = 'Something went wrong. Please try again.';
}
