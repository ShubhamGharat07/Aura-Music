import 'package:permission_handler/permission_handler.dart';

/// Permission helper (PRD 9.8). Wraps `permission_handler` so no widget
/// or BLoC imports the plugin directly.
final class PermissionService {
  /// Creates the service.
  const PermissionService();

  /// Requests notification permission (Android 13+ / POST_NOTIFICATIONS).
  /// Returns true when granted or not required.
  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  /// Requests install-packages permission (OTA updater only, PRD 9.8).
  Future<bool> requestInstallPackages() async =>
      (await Permission.requestInstallPackages.request()).isGranted;

  /// Whether notification permission is currently granted.
  Future<bool> hasNotification() => Permission.notification.isGranted;

  /// Requests the BLE scan permission (listen together, guest role).
  ///
  /// A no-op that reports granted on Android 11 and older, where the platform
  /// does not split Bluetooth into runtime permissions; scanning is gated by
  /// [requestLocation] there instead.
  Future<bool> requestBluetoothScan() async =>
      _granted(await Permission.bluetoothScan.request());

  /// Requests the BLE advertise permission (listen together, host role).
  Future<bool> requestBluetoothAdvertise() async =>
      _granted(await Permission.bluetoothAdvertise.request());

  /// Requests Bluetooth access on iOS/macOS, where CoreBluetooth covers both
  /// hosting and scanning with a single prompt.
  Future<bool> requestBluetooth() async =>
      _granted(await Permission.bluetooth.request());

  /// Requests the BLE connect permission (listen together, both roles).
  Future<bool> requestBluetoothConnect() async =>
      _granted(await Permission.bluetoothConnect.request());

  /// Requests foreground location, which gates BLE scanning on Android 11
  /// and older.
  Future<bool> requestLocation() async =>
      _granted(await Permission.locationWhenInUse.request());

  /// Opens the OS app settings (used after permanent denial).
  Future<bool> openSettings() => openAppSettings();

  static bool _granted(PermissionStatus status) =>
      status.isGranted || status.isLimited || status.isProvisional;
}
