import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';

// Listen together (PRD S06) repository contract. One device advertises and
// serves the link (host); the others link up to it (guests).

/// Party mode transport and session state.
abstract interface class PartyRepository {
  /// Emits the current session, then every change to it.
  Stream<PartySession> watch();

  /// Emits every message received from the linked side.
  Stream<PartyMessage> watchMessages();

  /// Advertises this device and serves the party link, so nearby devices can
  /// join the session.
  Future<Either<Failure, Unit>> host();

  /// Starts looking for nearby sessions to join, or stops when [active] is
  /// false.
  Future<Either<Failure, Unit>> discover({required bool active});

  /// Links to the session advertised by [peerId] and starts following it.
  Future<Either<Failure, Unit>> join(String peerId);

  /// Sends [snapshot] to the linked side: the full state when [full] is true,
  /// otherwise a position + transport tick. A no-op unless hosting.
  Future<Either<Failure, Unit>> publish(
    PartySnapshot snapshot, {
    required bool full,
  });

  /// Ends hosting, leaves the followed session, or stops scanning.
  Future<Either<Failure, Unit>> leave();
}
