import 'package:equatable/equatable.dart';

/// A user-created playlist (PRD S12/S13). Distinct from the remote catalog
/// `Playlist`; this one is local, editable and offline-first.

/// Local user playlist (metadata only).
final class UserPlaylist extends Equatable {
  /// Creates a user playlist.
  const UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.artUrl,
    this.songCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Local uuid (also the route id).
  final String id;

  /// Display name.
  final String name;

  /// Optional description.
  final String? description;

  /// Cover art URL (defaults to the first song's art).
  final String? artUrl;

  /// Number of songs currently in the playlist.
  final int songCount;

  /// Creation time.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    artUrl,
    songCount,
    createdAt,
    updatedAt,
  ];
}
