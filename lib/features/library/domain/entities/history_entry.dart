import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// One playback in the user's history (PRD S15).

/// A played track and when it played.
final class HistoryEntry extends Equatable {
  /// Creates a history entry.
  const HistoryEntry({required this.track, required this.playedAt});

  /// The track that was played.
  final Track track;

  /// When it was played.
  final DateTime playedAt;

  @override
  List<Object?> get props => [track, playedAt];
}
