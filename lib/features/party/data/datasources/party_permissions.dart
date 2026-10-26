import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import 'package:aura_music/core/services/permission_service.dart';

/// Asks for the Bluetooth permissions listen together needs (PRD S06).
abstract interface class PartyPermissionGate {
  /// Requests everything [host]ing (or joining) requires. Returns true when
  /// every permission is granted.
  Future<bool> request({required bool host});
}

/// [PartyPermissionGate] on top of [PermissionService].
///
/// The set depends on the role and the platform: hosting needs advertise,
/// joining needs scan, both need connect, and Android 11 or older additionally
/// gates a scan behind location, because the split Bluetooth permissions only
/// exist from Android 12 (API 31).
final class PartyPermissions implements PartyPermissionGate {
  /// Creates the helper.
  PartyPermissions(this._permissions, {DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final PermissionService _permissions;
  final DeviceInfoPlugin _deviceInfo;
  bool? _legacyAndroid;

  /// Requests everything [host]ing (or joining) requires. Returns true when
  /// every permission is granted.
  @override
  Future<bool> request({required bool host}) async {
    if (Platform.isIOS || Platform.isMacOS) {
      // CoreBluetooth asks once, for both roles.
      return _permissions.requestBluetooth();
    }
    if (!Platform.isAndroid) return true;
    final role = host
        ? await _permissions.requestBluetoothAdvertise()
        : await _permissions.requestBluetoothScan();
    final connect = await _permissions.requestBluetoothConnect();
    if (!role || !connect) return false;
    if (!await _needsLocation()) return true;
    return _permissions.requestLocation();
  }

  /// Android 11 (API 30) and older gate BLE scanning behind location.
  Future<bool> _needsLocation() async {
    final cached = _legacyAndroid;
    if (cached != null) return cached;
    var legacy = false;
    try {
      legacy = (await _deviceInfo.androidInfo).version.sdkInt < 31;
    } on Object {
      legacy = false;
    }
    return _legacyAndroid = legacy;
  }
}
