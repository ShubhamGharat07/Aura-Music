import 'package:flutter/services.dart';

/// Toggles the Android `FLAG_SECURE` window flag so screenshots and recents
/// thumbnails are blocked (PRD 9.7 / S20). The platform channel is the only
/// entry point — widgets and BLoCs never touch it directly.

/// Secure-screen bridge.
final class ScreenSecurityService {
  /// Creates the service (a custom [channel] is used by tests).
  const ScreenSecurityService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'aura/screen';

  final MethodChannel _channel;

  /// Enables or disables secure-screen mode. No-op on unsupported platforms.
  Future<void> setSecure(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // Desktop / widget tests without a handler.
    } on PlatformException {
      // Older native build without the handler.
    }
  }
}
