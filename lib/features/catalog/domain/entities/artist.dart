import 'package:equatable/equatable.dart';

/// Artist metadata (catalog domain entity, PRD 5.1).

/// A music artist.
final class Artist extends Equatable {
  /// Creates an artist.
  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.role,
  });

  /// Stable id (`jiosaavn:<id>`).
  final String id;

  /// Display name.
  final String name;

  /// Portrait image URL.
  final String? imageUrl;

  /// Role label (e.g. `Singer`), when provided.
  final String? role;

  @override
  List<Object?> get props => [id, name, imageUrl, role];
}
