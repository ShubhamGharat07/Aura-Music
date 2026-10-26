import 'package:equatable/equatable.dart';

/// Playlist metadata (catalog domain entity, PRD 5.1).

/// A curated playlist.
final class Playlist extends Equatable {
  /// Creates a playlist.
  const Playlist({
    required this.id,
    required this.title,
    this.artUrl,
    this.songCount,
    this.subtitle,
  });

  /// Stable id (`jiosaavn:<id>`).
  final String id;

  /// Playlist title.
  final String title;

  /// Artwork URL (square).
  final String? artUrl;

  /// Number of songs, when known.
  final int? songCount;

  /// Secondary line (curator / language), when known.
  final String? subtitle;

  @override
  List<Object?> get props => [id, title, artUrl, songCount, subtitle];
}
