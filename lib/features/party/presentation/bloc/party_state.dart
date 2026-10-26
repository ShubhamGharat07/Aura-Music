import 'package:equatable/equatable.dart';

import 'package:aura_music/features/party/domain/entities/party_session.dart';

// Listen together (PRD S06) state: a thin wrapper over [PartySession] so the
// sheet renders straight from the domain model.

/// UI state of the party sheet.
final class PartyState extends Equatable {
  /// Creates the state.
  const PartyState({this.session = const PartySession(), this.busy = false});

  /// Current session (role, status, peers, notice).
  final PartySession session;

  /// A start, join or leave call is in flight.
  final bool busy;

  /// Copies with overrides.
  PartyState copyWith({PartySession? session, bool? busy}) =>
      PartyState(session: session ?? this.session, busy: busy ?? this.busy);

  @override
  List<Object?> get props => [session, busy];
}
