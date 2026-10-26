import 'package:equatable/equatable.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// Local album / artist groups derived from liked songs (PRD S12 chips).

/// A group of local tracks with a shared album or artist.
final class TrackCollection extends Equatable {
  /// Creates a collection.
  const TrackCollection({
    required this.id,
    required this.title,
    this.subtitle,
    this.artUrl,
    required this.tracks,
  });

  /// Stable id (lower-cased group name).
  final String id;

  /// Album or artist name.
  final String title;

  /// Secondary line (artist for albums; null for artists).
  final String? subtitle;

  /// Cover art (first track's art).
  final String? artUrl;

  /// Tracks in the group (first-seen order).
  final List<Track> tracks;

  /// Number of tracks.
  int get count => tracks.length;

  @override
  List<Object?> get props => [id, title, subtitle, artUrl, tracks];
}

/// Groups [tracks] by album name (case-insensitive), first-seen order.
List<TrackCollection> groupByAlbum(List<Track> tracks) => _group(
  tracks,
  (track) => track.album,
  fallback: 'Unknown album',
  subtitleOf: (track) => track.artist,
);

/// Groups [tracks] by primary artist (case-insensitive), first-seen order.
List<TrackCollection> groupByArtist(List<Track> tracks) =>
    _group(tracks, (track) => track.artist, fallback: 'Unknown artist');

List<TrackCollection> _group(
  List<Track> tracks,
  String? Function(Track) keyOf, {
  required String fallback,
  String? Function(Track)? subtitleOf,
}) {
  final groups = <String, List<Track>>{};
  final titles = <String, String>{};
  final order = <String>[];
  for (final track in tracks) {
    final raw = keyOf(track);
    final title = raw == null || raw.trim().isEmpty ? fallback : raw.trim();
    final key = title.toLowerCase();
    if (!groups.containsKey(key)) {
      groups[key] = <Track>[];
      titles[key] = title;
      order.add(key);
    }
    groups[key]!.add(track);
  }
  return List.unmodifiable([
    for (final key in order)
      TrackCollection(
        id: key,
        title: titles[key]!,
        subtitle: subtitleOf == null ? null : subtitleOf(groups[key]!.first),
        artUrl: groups[key]!.first.artUrl,
        tracks: List.unmodifiable(groups[key]!),
      ),
  ]);
}
