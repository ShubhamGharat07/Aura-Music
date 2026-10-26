import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Links to the session of [peerId] and follows its playback.
final class JoinParty {
  /// Creates the use case.
  const JoinParty(this._repository);

  final PartyRepository _repository;

  /// Joins the session advertised by [peerId].
  Future<Either<Failure, Unit>> call(String peerId) => _repository.join(peerId);
}
