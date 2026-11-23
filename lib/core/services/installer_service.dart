import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android PackageInstaller via `aura/installer` channel.
class InstallerService {
  /// Default constructor.
  const InstallerService();

  static const MethodChannel _channel = MethodChannel('aura/installer');

  /// Checks whether the app has permission to install unknown apps (Android 8+).
  Future<bool> canInstallUnknownSources() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'canInstallUnknownSources',
      );
      return result ?? false;
    } on Object catch (e) {
      debugPrint('[InstallerService] Error checking install permission: $e');
      return false;
    }
  }

  /// Opens the Android "Install Unknown Apps" permission screen for Aura Music.
  Future<bool> openInstallPermissionSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'openInstallPermissionSettings',
      );
      return result ?? false;
    } on Object catch (e) {
      debugPrint('[InstallerService] Error opening permission settings: $e');
      return false;
    }
  }

  /// Free bytes in the app's private OTA storage.
  Future<int> availableBytes() async =>
      await _channel.invokeMethod<int>('availableUpdateBytes') ?? 0;

  /// Opens Android's installer for a verified APK.
  Future<bool> installApk(String filePath, {required int versionCode}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    final result = await _channel.invokeMethod<bool>('installApk', {
      'filePath': filePath,
      'versionCode': versionCode,
    });
    return result ?? false;
  }
}
