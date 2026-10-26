import 'package:equatable/equatable.dart';

import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';

// Listen together (PRD S06): the messages exchanged over the link. Transport
// framing lives in the codec, so these are the decoded payloads only.

/// Base message of the party protocol.
sealed class PartyMessage extends Equatable {
  /// Creates a message.
  const PartyMessage();
}

/// Host → guests: the complete session state (queue, index, transport).
final class PartyStateMessage extends PartyMessage {
  /// Creates a state message.
  const PartyStateMessage(this.snapshot);

  /// Shared playback state.
  final PartySnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// Host → guests: position and transport only, sent while the queue is
/// unchanged so a 5 s tick stays small.
final class PartyTickMessage extends PartyMessage {
  /// Creates a tick message.
  const PartyTickMessage({
    required this.index,
    required this.position,
    required this.playing,
  });

  /// Current queue index on the host.
  final int index;

  /// Current position on the host.
  final Duration position;

  /// Whether the host is playing.
  final bool playing;

  @override
  List<Object?> get props => [index, position, playing];
}

/// Guest → host: announcing itself, which also asks for the current state.
final class PartyHelloMessage extends PartyMessage {
  /// Creates a hello message.
  const PartyHelloMessage(this.name);

  /// Name of the joining device.
  final String name;

  @override
  List<Object?> get props => [name];
}

/// Either side: leaving the session.
final class PartyByeMessage extends PartyMessage {
  /// Creates a bye message.
  const PartyByeMessage();

  @override
  List<Object?> get props => [];
}
