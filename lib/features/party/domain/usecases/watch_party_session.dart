import 'package:aura_music/features/party/domain/entities/party_session.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Watches the party session.
final class WatchPartySession {
  /// Creates the use case.
  const WatchPartySession(this._repository);

  final PartyRepository _repository;

  /// Emits the current session and every change to it.
  Stream<PartySession> call() => _repository.watch();
}
