import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// Represents a podcast episode entity.
final class PodcastEpisode extends Equatable {
  /// Creates a podcast episode.
  const PodcastEpisode({
    required this.id,
    required this.title,
    this.showId,
    this.showTitle,
    this.subtitle,
    this.artUrl,
    this.description,
    this.duration = Duration.zero,
    this.releaseDate,
    this.seasonNumber,
    this.episodeNumber,
    this.streamUrl,
  });

  /// Episode unique id.
  final String id;

  /// Episode title.
  final String title;

  /// Parent show id.
  final String? showId;

  /// Parent show title.
  final String? showTitle;

  /// Episode subtitle or guest name.
  final String? subtitle;

  /// Episode high-res artwork URL.
  final String? artUrl;

  /// Episode description/synopsis.
  final String? description;

  /// Episode length.
  final Duration duration;

  /// Human-readable release date string.
  final String? releaseDate;

  /// Season number.
  final int? seasonNumber;

  /// Episode sequence or number.
  final int? episodeNumber;

  /// Decrypted high-bitrate audio stream URL.
  final String? streamUrl;

  /// Seamlessly converts this episode to a playable [Track] for Aura Music's
  /// audio engine, lockscreen, equalizer, and disk cache.
  Track toTrack() {
    return Track(
      id: 'podcast:$id',
      title: title,
      artist: (subtitle != null && subtitle!.trim().isNotEmpty)
          ? subtitle!.trim()
          : (showTitle ?? 'Podcast'),
      album: showTitle ?? 'Podcast',
      artUrl: artUrl,
      duration: duration,
      streamUrl: streamUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        showId,
        showTitle,
        subtitle,
        artUrl,
        description,
        duration,
        releaseDate,
        seasonNumber,
        episodeNumber,
        streamUrl,
      ];
}
