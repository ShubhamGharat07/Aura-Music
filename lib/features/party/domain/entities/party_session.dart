import 'package:equatable/equatable.dart';

import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_role.dart';
import 'package:aura_music/features/party/domain/entities/party_status.dart';

// Listen together (PRD S06): everything the party sheet needs to render.

/// State of the local party session.
final class PartySession extends Equatable {
  /// Creates a session, [PartyStatus.idle] by default.
  const PartySession({
    this.role,
    this.status = PartyStatus.idle,
    this.peers = const [],
    this.hostName,
    this.notice,
  });

  /// This device's side of the link, or null when idle.
  final PartyRole? role;

  /// Lifecycle status.
  final PartyStatus status;

  /// Hosting: the devices following this one. Guest: nearby sessions.
  final List<PartyPeer> peers;

  /// Guest: name of the session being followed.
  final String? hostName;

  /// User-facing message explaining the current status (denial, failure, or
  /// why a session ended). Cleared whenever a new event replaces it.
  final String? notice;

  /// Nothing is running.
  bool get isIdle => status == PartyStatus.idle;

  /// Advertising and serving the link.
  bool get isHosting => status == PartyStatus.hosting;

  /// Looking for sessions to join.
  bool get isScanning => status == PartyStatus.scanning;

  /// Linking to a session.
  bool get isConnecting => status == PartyStatus.connecting;

  /// Guest link is live.
  bool get isConnected => status == PartyStatus.connected;

  /// A guest following a host (the role that mirrors remote playback).
  bool get isFollowing => role == PartyRole.guest && isConnected;

  /// Any non-idle status: drives the accent state of the player button.
  bool get isActive => status != PartyStatus.idle;

  /// Copies with overrides. Omitting [notice] clears it, the same way
  /// `PlayerState.copyWith` clears its error, so a stale message never sticks.
  PartySession copyWith({
    PartyRole? role,
    PartyStatus? status,
    List<PartyPeer>? peers,
    String? hostName,
    String? notice,
  }) {
    return PartySession(
      role: role ?? this.role,
      status: status ?? this.status,
      peers: peers ?? this.peers,
      hostName: hostName ?? this.hostName,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [role, status, peers, hostName, notice];
}
