import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:aura_music/features/party/domain/entities/party_peer.dart';

// Listen together (PRD S06): the raw BLE link, kept behind an interface so the
// repository is testable without a radio.

/// Base transport event.
sealed class PartyTransportEvent extends Equatable {
  /// Creates an event.
  const PartyTransportEvent();

  @override
  List<Object?> get props => [];
}

/// The list of visible devices changed (guest: nearby sessions).
final class PartyPeersChanged extends PartyTransportEvent {
  /// Creates a peers event.
  const PartyPeersChanged(this.peers);

  /// Devices seen in the current scan.
  final List<PartyPeer> peers;

  @override
  List<Object?> get props => [peers];
}

/// Guest: the link to the host came up.
final class PartyLinkUp extends PartyTransportEvent {
  /// Creates a link event.
  const PartyLinkUp({required this.peerId, required this.name});

  /// Device identifier of the host.
  final String peerId;

  /// Display name of the host.
  final String name;

  @override
  List<Object?> get props => [peerId, name];
}

/// Guest: the link to the host went down.
final class PartyLinkDown extends PartyTransportEvent {
  /// Creates an unlink event.
  const PartyLinkDown({this.reason});

  /// Why the link ended, when the platform says.
  final String? reason;

  @override
  List<Object?> get props => [reason];
}

/// Host: whether any guest currently holds the link.
final class PartySubscribersChanged extends PartyTransportEvent {
  /// Creates a subscriber event.
  const PartySubscribersChanged({required this.subscribed});

  /// True once a guest is attached and can be notified.
  final bool subscribed;

  @override
  List<Object?> get props => [subscribed];
}

/// Bytes arrived from the other side.
final class PartyDataReceived extends PartyTransportEvent {
  /// Creates a data event.
  const PartyDataReceived(this.bytes);

  /// Raw bytes of one or more frames.
  final Uint8List bytes;

  @override
  List<Object?> get props => [bytes];
}

/// The radio or the platform failed.
final class PartyTransportFailure extends PartyTransportEvent {
  /// Creates a failure event.
  const PartyTransportFailure(this.message);

  /// User-facing reason.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Raw BLE link used by listen together (PRD S06).
abstract interface class PartyTransport {
  /// Platform events, in arrival order.
  Stream<PartyTransportEvent> get events;

  /// This device's display name, used in the message that announces it.
  Future<String> deviceName();

  /// Whether this device can take part: the hardware supports BLE and the
  /// radio is switched on. [host] picks advertising over scanning.
  Future<bool> isReady({required bool host});

  /// Advertises this device as [name] and serves the GATT link (host).
  Future<void> host({required String name});

  /// Starts scanning for nearby sessions (guest).
  Future<void> startScan();

  /// Stops scanning.
  Future<void> stopScan();

  /// Connects to the session advertised by [peerId] (guest).
  Future<void> join(String peerId);

  /// Sends [bytes] to the other side.
  Future<void> send(Uint8List bytes);

  /// Tears down advertising, scanning and any link.
  Future<void> stop();
}
