import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/features/party/data/datasources/party_transport.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';

// Listen together (PRD S06) over BLE.
//
// The host is the peripheral: it advertises the service below and serves a GATT
// service with one notifying characteristic (host â†’ guests) and one writable
// one (guest â†’ host). A guest is the central: it scans for the service, links
// up and subscribes. Both plugins come from the same author and are designed to
// coexist, so one process can take either role.

/// Service uuid the host advertises and the guest scans for.
const String partyServiceUuid = 'a9f0b1c2-3d4e-5f60-7a8b-9c0d1e2f3a4b';

/// Characteristic the host notifies on (host â†’ guests).
const String partyTxCharacteristicUuid = 'a9f0b1c3-3d4e-5f60-7a8b-9c0d1e2f3a4b';

/// Characteristic a guest writes to (guest â†’ host).
const String partyRxCharacteristicUuid = 'a9f0b1c4-3d4e-5f60-7a8b-9c0d1e2f3a4b';

/// BLE implementation of [PartyTransport].
final class BlePartyTransport implements PartyTransport {
  /// Creates the transport.
  BlePartyTransport({
    FlutterBlePeripheral? peripheral,
    DeviceInfoPlugin? deviceInfo,
  }) : _peripheral = peripheral ?? FlutterBlePeripheral(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final FlutterBlePeripheral _peripheral;
  final DeviceInfoPlugin _deviceInfo;
  final StreamController<PartyTransportEvent> _events =
      StreamController<PartyTransportEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  final Map<String, String> _scanNames = {};

  BluetoothDevice? _guestLink;
  BluetoothCharacteristic? _writeTo;
  bool _hosting = false;
  String? _deviceName;
  int _attempt = 0;

  @override
  Stream<PartyTransportEvent> get events => _events.stream;

  @override
  Future<String> deviceName() async {
    final cached = _deviceName;
    if (cached != null) return cached;
    var name = '';
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        name = '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        name = (await _deviceInfo.iosInfo).name;
      } else if (Platform.isWindows) {
        name = (await _deviceInfo.windowsInfo).computerName;
      }
    } on Object {
      // The generic name works just as well for the host's guest list.
    }
    name = name.trim();
    return _deviceName = name.isEmpty ? 'Aura Music' : name;
  }

  @override
  Future<bool> isReady({required bool host}) async {
    try {
      if (host) {
        return await _peripheral.isSupported && await _peripheral.isBluetoothOn;
      }
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return false;
      // The adapter reports `unknown` until the platform answers, and that
      // first answer can take a moment on a cold start, so a single peek would
      // read as "Bluetooth is off" for a phone that is fine.
      final state = await FlutterBluePlus.adapterState
          .where((state) => state != BluetoothAdapterState.unknown)
          .first
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => BluetoothAdapterState.unknown,
          );
      return state == BluetoothAdapterState.on;
    } on Object {
      // An unusable adapter (or a platform without BLE) reports false, which
      // the repository turns into an "unsupported" session.
      return false;
    }
  }

  @override
  Future<void> host({required String name}) async {
    await stop();
    // Listened to before the advertisement goes on air: a guest that attaches
    // within the first seconds must not be missed.
    _subs.add(
      _peripheral.onDataReceived.listen(
        (data) => _emit(PartyDataReceived(Uint8List.fromList(data))),
      ),
    );
    _subs.add(
      _peripheral.onSubscriptionChanged.listen(
        (subscribed) => _emit(PartySubscribersChanged(subscribed: subscribed)),
      ),
    );
    final state = await _peripheral.start(
      advertiseData: AdvertiseDataCore(
        serviceUuid: partyServiceUuid,
        localName: _advertisedName(name),
      ),
      gattServer: const GattServerSettings(
        serviceUuid: partyServiceUuid,
        txCharacteristicUuid: partyTxCharacteristicUuid,
        rxCharacteristicUuid: partyRxCharacteristicUuid,
      ),
      // These settings are not optional: leaving them out makes Android
      // advertise non-connectable in low-power mode, so a guest would find the
      // session, tap it, and watch the link fail to attach.
      androidSettings: const AndroidAdvertiseSettings(
        advertiseSettings: AdvertiseSettings(
          advertiseMode: AdvertiseMode.advertiseModeLowLatency,
          txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
          connectable: true,
        ),
        // Android ignores the advertised local name, so the device name rides
        // along in the scan response instead.
        advertiseResponseData: AndroidAdvertiseData(includeDeviceName: true),
      ),
    );
    // A refused advertisement is reported rather than thrown, so without this
    // the app would claim to be hosting with nothing on air.
    if (state != PeripheralBluetoothState.ready) {
      throw StateError(_advertiseFailure(state));
    }
    _hosting = true;
  }

  @override
  Future<void> startScan() async {
    // A fresh scan means any pending join was abandoned.
    _attempt++;
    await stopScan();
    _scanNames.clear();
    _subs.add(
      FlutterBluePlus.scanResults.listen((results) {
        final peers = <PartyPeer>[];
        for (final result in results) {
          final id = result.device.remoteId.str;
          final name = _scanName(result);
          _scanNames[id] = name;
          peers.add(PartyPeer(id: id, name: name, rssi: result.rssi));
        }
        peers.sort((a, b) => (b.rssi ?? -127).compareTo(a.rssi ?? -127));
        _emit(PartyPeersChanged(peers));
      }),
    );
    await FlutterBluePlus.startScan(
      withServices: [Guid(partyServiceUuid)],
      timeout: AppConstants.partyScanTimeout,
    );
  }

  @override
  Future<void> stopScan() async {
    if (!FlutterBluePlus.isScanningNow) return;
    try {
      await FlutterBluePlus.stopScan();
    } on Object {
      // Nothing to stop: the scan already timed out.
    }
  }

  @override
  Future<void> join(String peerId) async {
    // Bumped by every join/cancel: a link that finishes connecting after the
    // user backed out must not be kept alive.
    final attempt = ++_attempt;
    await stopScan();
    final device = BluetoothDevice.fromId(peerId);
    await device.connect(timeout: AppConstants.partyConnectTimeout);
    if (attempt != _attempt) {
      unawaited(_disconnect(device));
      return;
    }
    // A frame is up to [_maxFramePayload] bytes plus its header, while a fresh
    // link starts at the default 23-byte ATT MTU (~20 usable bytes): without
    // this, every write is truncated and nothing arrives. Android negotiates,
    // iOS just reports what it already has.
    try {
      await device.requestMtu(517);
    } on Object {
      // The platform will not negotiate: frames stay small enough to fit.
    }
    final characteristics = await _characteristicsOf(device);
    if (attempt != _attempt) {
      unawaited(_disconnect(device));
      return;
    }
    final notifyOn = characteristics.$1;
    final writeTo = characteristics.$2;
    if (notifyOn == null || writeTo == null) {
      unawaited(_disconnect(device));
      throw StateError('That device is not sharing a session.');
    }
    _guestLink = device;
    _writeTo = writeTo;
    try {
      await notifyOn.setNotifyValue(true);
    } on Object {
      // Subscribing failed: drop the half-open link instead of leaving it up.
      _guestLink = null;
      _writeTo = null;
      unawaited(_disconnect(device));
      rethrow;
    }
    _subs.add(
      notifyOn.onValueReceived.listen(
        (value) => _emit(PartyDataReceived(Uint8List.fromList(value))),
      ),
    );
    var sawConnected = false;
    _subs.add(
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          sawConnected = true;
          return;
        }
        // Some stacks report the link as still down for the first frames after
        // connecting; only a drop *after* a live link ends the session.
        if (state == BluetoothConnectionState.disconnected && sawConnected) {
          _emit(const PartyLinkDown(reason: 'The session ended.'));
        }
      }),
    );
    _emit(
      PartyLinkUp(peerId: peerId, name: _scanNames[peerId] ?? 'Nearby session'),
    );
  }

  @override
  Future<void> send(Uint8List bytes) async {
    if (_hosting) {
      await _peripheral.sendData(bytes);
      return;
    }
    final writeTo = _writeTo;
    if (writeTo == null) return;
    // Guest â†’ host is tiny but must not be dropped (hello builds the host's
    // guest list, bye ends the session), so it goes as a long write with a
    // response instead of fire-and-forget.
    await writeTo.write(bytes, withoutResponse: false, allowLongWrite: true);
  }

  @override
  Future<void> stop() async {
    _attempt++;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _writeTo = null;
    _scanNames.clear();
    final link = _guestLink;
    _guestLink = null;
    if (link != null) unawaited(_disconnect(link));
    await stopScan();
    if (_hosting) {
      _hosting = false;
      try {
        await _peripheral.stop();
      } on Object {
        // Advertising had already stopped.
      }
    }
  }

  /// Finds the party characteristics on [device], or a pair of nulls when the
  /// service is not there.
  ///
  /// The host puts the advertisement on air a moment before its GATT service is
  /// added, so a guest that attaches inside that window discovers no service at
  /// all. That is a race, not a refusal, so the lookup is retried briefly
  /// instead of ending the session.
  Future<(BluetoothCharacteristic?, BluetoothCharacteristic?)>
  _characteristicsOf(BluetoothDevice device) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      final found = await _discover(device);
      if (found.$1 != null && found.$2 != null) return found;
    }
    return (null, null);
  }

  Future<(BluetoothCharacteristic?, BluetoothCharacteristic?)> _discover(
    BluetoothDevice device,
  ) async {
    BluetoothCharacteristic? notifyOn;
    BluetoothCharacteristic? writeTo;
    try {
      for (final service in await device.discoverServices()) {
        if (service.uuid.str.toLowerCase() != partyServiceUuid) continue;
        for (final characteristic in service.characteristics) {
          final uuid = characteristic.uuid.str.toLowerCase();
          if (uuid == partyTxCharacteristicUuid) notifyOn = characteristic;
          if (uuid == partyRxCharacteristicUuid) writeTo = characteristic;
        }
      }
    } on Object {
      // A discovery that fails mid-flight (a drop, or one already running) is
      // retried by the caller.
    }
    return (notifyOn, writeTo);
  }

  /// iOS caps an advertised local name at 10 bytes; Android ignores it.
  String _advertisedName(String name) =>
      name.length <= 10 ? name : name.substring(0, 10);

  /// User-facing reason an advertisement could not go on air.
  String _advertiseFailure(PeripheralBluetoothState state) => switch (state) {
    PeripheralBluetoothState.turnedOff => 'Bluetooth is off on this device.',
    PeripheralBluetoothState.unsupported =>
      'This device cannot host a session.',
    PeripheralBluetoothState.denied ||
    PeripheralBluetoothState.permanentlyDenied =>
      'Bluetooth access was refused.',
    _ => 'The session could not be started.',
  };

  String _scanName(ScanResult result) {
    final platform = result.device.platformName.trim();
    if (platform.isNotEmpty) return platform;
    final advertised = result.advertisementData.advName.trim();
    if (advertised.isNotEmpty) return advertised;
    return 'Nearby session';
  }

  Future<void> _disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } on Object {
      // The link was already gone.
    }
  }

  void _emit(PartyTransportEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
