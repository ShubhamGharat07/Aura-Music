import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Stops hosting, leaves a session, or stops scanning.
final class LeaveParty {
  /// Creates the use case.
  const LeaveParty(this._repository);

  final PartyRepository _repository;

  /// Ends the local party session.
  Future<Either<Failure, Unit>> call() => _repository.leave();
}
