import 'package:equatable/equatable.dart';

// Listen together (PRD S06): a device visible to this one.

/// A nearby session (guest view) or a device following this one (host view).
final class PartyPeer extends Equatable {
  /// Creates a peer.
  const PartyPeer({required this.id, required this.name, this.rssi});

  /// Platform identifier of the device (`remoteId`).
  final String id;

  /// Display name: the advertised session name, or the device name.
  final String name;

  /// Signal strength in dBm, when the platform reports one.
  final int? rssi;

  @override
  List<Object?> get props => [id, name, rssi];
}
