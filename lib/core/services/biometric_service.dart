import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` so widgets and BLoCs never import the plugin
/// (PRD 9.7 / S20). Biometrics fall back to the device credential (PIN,
/// pattern, passcode) because `biometricOnly` stays false.

/// Biometric / device-credential bridge.
final class BiometricService {
  /// Creates the service (a custom [auth] is used by tests).
  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can authenticate at all.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  /// Prompts the user and returns true only on success.
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        sensitiveTransaction: false,
      );
    } on Object {
      return false;
    }
  }
}
