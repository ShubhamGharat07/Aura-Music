import 'package:equatable/equatable.dart';

/// Mood / genre browse channel (catalog domain entity, PRD S03).

/// A JioSaavn mood or genre channel, used by the home "Moods & genres" row and
/// by search. [name] doubles as the catalog query that resolves its songs.
final class Genre extends Equatable {
  /// Creates a genre.
  const Genre({required this.id, required this.name, this.artUrl});

  /// Raw JioSaavn channel id.
  final String id;

  /// Display name (e.g. `Chill`, `Hip Hop`).
  final String name;

  /// Artwork URL (square).
  final String? artUrl;

  @override
  List<Object?> get props => [id, name, artUrl];
}
