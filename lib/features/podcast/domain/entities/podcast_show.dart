import 'package:equatable/equatable.dart';

/// Represents a podcast show entity.
final class PodcastShow extends Equatable {
  /// Creates a podcast show.
  const PodcastShow({
    required this.id,
    required this.title,
    this.subtitle,
    this.artUrl,
    this.description,
    this.seasonCount,
    this.latestSeason,
    this.badge,
    this.explicitContent = false,
  });

  /// Unique show id (raw JioSaavn show id).
  final String id;

  /// Show title (e.g. "The Ranveer Show", "Talking Music").
  final String title;

  /// Host, author or studio subtitle.
  final String? subtitle;

  /// 500x500 high-res cover art URL.
  final String? artUrl;

  /// Show synopsis / description.
  final String? description;

  /// Number of seasons if available.
  final int? seasonCount;

  /// Latest season number.
  final int? latestSeason;

  /// Show badge or category (e.g. "EXCLUSIVE", "ORIGINAL").
  final String? badge;

  /// Whether the show contains explicit content.
  final bool explicitContent;

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        artUrl,
        description,
        seasonCount,
        latestSeason,
        badge,
        explicitContent,
      ];
}
