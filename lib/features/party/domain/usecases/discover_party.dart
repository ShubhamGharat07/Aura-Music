import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Looks for nearby sessions, or stops looking.
final class DiscoverParty {
  /// Creates the use case.
  const DiscoverParty(this._repository);

  final PartyRepository _repository;

  /// Starts the scan when [active], stops it otherwise.
  Future<Either<Failure, Unit>> call({required bool active}) =>
      _repository.discover(active: active);
}
