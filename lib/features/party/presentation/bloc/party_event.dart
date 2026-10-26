import 'package:equatable/equatable.dart';

import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_peer.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';

// Listen together (PRD S06) events. Hand-written and sealed, like the player's.

/// Base party event.
sealed class PartyEvent extends Equatable {
  /// Creates an event.
  const PartyEvent();

  @override
  List<Object?> get props => [];
}

/// Starts hosting a session on this device.
final class PartyHostRequested extends PartyEvent {
  /// Creates the event.
  const PartyHostRequested();
}

/// Starts or stops looking for nearby sessions.
final class PartyDiscoveryToggled extends PartyEvent {
  /// Creates the event.
  const PartyDiscoveryToggled({required this.active});

  /// Whether the scan should be running.
  final bool active;

  @override
  List<Object?> get props => [active];
}

/// Links to the session of [peer] and follows it.
final class PartyJoinRequested extends PartyEvent {
  /// Creates the event.
  const PartyJoinRequested(this.peer);

  /// Session to join.
  final PartyPeer peer;

  @override
  List<Object?> get props => [peer];
}

/// Ends hosting, leaves the followed session, or stops scanning.
final class PartyLeaveRequested extends PartyEvent {
  /// Creates the event.
  const PartyLeaveRequested();
}

/// Internal: the repository reported a session change.
final class PartySessionChanged extends PartyEvent {
  /// Creates the event.
  const PartySessionChanged(this.session);

  /// Latest session.
  final PartySession session;

  @override
  List<Object?> get props => [session];
}

/// Internal: a message arrived from the other side of the link.
final class PartyMessageReceived extends PartyEvent {
  /// Creates the event.
  const PartyMessageReceived(this.message);

  /// Decoded message.
  final PartyMessage message;

  @override
  List<Object?> get props => [message];
}

/// Internal: the local player changed, so the host re-shares its state.
final class PartyPlayerChanged extends PartyEvent {
  /// Creates the event.
  const PartyPlayerChanged();
}

/// Internal: the periodic re-sync tick.
final class PartyTickElapsed extends PartyEvent {
  /// Creates the event.
  const PartyTickElapsed();
}
