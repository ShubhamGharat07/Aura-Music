import 'package:aura_music/features/party/domain/entities/party_message.dart';
import 'package:aura_music/features/party/domain/repositories/party_repository.dart';

/// Listen together (PRD S06).

/// Watches the messages received from the linked side.
final class WatchPartyMessages {
  /// Creates the use case.
  const WatchPartyMessages(this._repository);

  final PartyRepository _repository;

  /// Emits every decoded incoming message.
  Stream<PartyMessage> call() => _repository.watchMessages();
}
