import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Starts hosting a party session.
final class HostParty {
  /// Creates the use case.
  const HostParty(this._repository);

  final PartyRepository _repository;

  /// Advertises this device and serves the link.
  Future<Either<Failure, Unit>> call() => _repository.host();
}
