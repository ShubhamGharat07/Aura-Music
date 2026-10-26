import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';

/// JioSaavn playlist DTOs (PRD 5.1 data layer).

/// A playlist node (search result or `playlist.getDetails`).
final class JiosaavnPlaylistModel {
  /// Creates a playlist model.
  const JiosaavnPlaylistModel({
    required this.id,
    this.title,
    this.name,
    this.imageUrl,
    this.subtitle,
    this.songCount,
  });

  /// Parses a playlist JSON object.
  factory JiosaavnPlaylistModel.fromJson(Map<String, dynamic> json) {
    final info = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return JiosaavnPlaylistModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String?,
      name: json['name'] as String?,
      imageUrl: json['image'] as String?,
      subtitle: json['subtitle'] as String?,
      songCount: int.tryParse(
        '${json['list_count'] ?? json['numsongs'] ?? info['song_count'] ?? ''}',
      ),
    );
  }

  /// Parses a JSON array of playlist objects (missing / malformed tolerated).
  static List<JiosaavnPlaylistModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnPlaylistModel.fromJson)
          .toList(growable: false);

  /// Raw JioSaavn id.
  final String id;

  /// Title variants.
  final String? title;

  /// Name variant.
  final String? name;

  /// Artwork URL (`150x150`).
  final String? imageUrl;

  /// Secondary line (curator / language).
  final String? subtitle;

  /// Song count.
  final int? songCount;

  /// Best available raw title (`title` → `name`).
  String? get rawTitle => title ?? name;
}

/// `playlist.getDetails` response: playlist metadata plus ordered songs.
final class JiosaavnPlaylistDetailModel {
  /// Creates a playlist detail model.
  const JiosaavnPlaylistDetailModel({
    required this.playlist,
    this.songs = const <JiosaavnSongModel>[],
  });

  /// Parses the playlist-detail JSON object.
  factory JiosaavnPlaylistDetailModel.fromJson(Map<String, dynamic> json) =>
      JiosaavnPlaylistDetailModel(
        playlist: JiosaavnPlaylistModel.fromJson(json),
        songs: JiosaavnSongModel.listFrom(json['list']),
      );

  /// Playlist metadata.
  final JiosaavnPlaylistModel playlist;

  /// Ordered playlist songs.
  final List<JiosaavnSongModel> songs;
}
