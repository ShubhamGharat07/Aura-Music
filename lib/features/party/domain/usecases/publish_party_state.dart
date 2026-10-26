import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/entities/party_snapshot.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Shares the host's state with its guests.
final class PublishPartyState {
  /// Creates the use case.
  const PublishPartyState(this._repository);

  final PartyRepository _repository;

  /// Sends [snapshot] in full when [full], else as a position tick.
  Future<Either<Failure, Unit>> call(
    PartySnapshot snapshot, {
    required bool full,
  }) => _repository.publish(snapshot, full: full);
}
