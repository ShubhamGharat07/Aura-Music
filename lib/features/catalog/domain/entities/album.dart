import 'package:equatable/equatable.dart';

/// Album metadata (catalog domain entity, PRD 5.1). Shared by search and the
/// album screen; pure Dart, no framework imports.

/// A music album.
final class Album extends Equatable {
  /// Creates an album.
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artUrl,
    this.year,
    this.songCount,
    this.language,
  });

  /// Stable id (`jiosaavn:<perma>`).
  final String id;

  /// Album title.
  final String title;

  /// Primary artist(s).
  final String artist;

  /// Artwork URL (square).
  final String? artUrl;

  /// Release year, when known.
  final int? year;

  /// Number of songs, when known.
  final int? songCount;

  /// Catalog language code (`hindi`, `tamil`, …), when the catalog says.
  final String? language;

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    artUrl,
    year,
    songCount,
    language,
  ];
}
