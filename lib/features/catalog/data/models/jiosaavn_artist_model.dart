import 'package:aura_music/features/catalog/data/models/jiosaavn_album_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';

/// JioSaavn artist DTOs (PRD 5.1 data layer).

/// An artist node (search result or `artist.getArtistPageDetails`).
final class JiosaavnArtistModel {
  /// Creates an artist model.
  const JiosaavnArtistModel({
    required this.id,
    this.title,
    this.name,
    this.imageUrl,
    this.role,
  });

  /// Parses an artist JSON object (`artistId` wins over `id`).
  factory JiosaavnArtistModel.fromJson(Map<String, dynamic> json) =>
      JiosaavnArtistModel(
        id: '${json['artistId'] ?? json['id'] ?? ''}',
        title: json['title'] as String?,
        name: json['name'] as String?,
        imageUrl: json['image'] as String?,
        role: json['role'] as String?,
      );

  /// Parses a JSON array of artist objects (missing / malformed tolerated).
  static List<JiosaavnArtistModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnArtistModel.fromJson)
          .toList(growable: false);

  /// Raw JioSaavn id.
  final String id;

  /// Title variant.
  final String? title;

  /// Name variant.
  final String? name;

  /// Portrait image URL.
  final String? imageUrl;

  /// Role label (e.g. `Singer`).
  final String? role;

  /// Best available raw name (`title` → `name`).
  String? get rawName => title ?? name;
}

/// `artist.getArtistPageDetails` response.
final class JiosaavnArtistDetailModel {
  /// Creates an artist detail model.
  const JiosaavnArtistDetailModel({
    required this.artist,
    this.topSongs = const <JiosaavnSongModel>[],
    this.albums = const <JiosaavnAlbumModel>[],
    this.followerCount,
    this.bio,
  });

  /// Parses the artist-page JSON object.
  factory JiosaavnArtistDetailModel.fromJson(Map<String, dynamic> json) =>
      JiosaavnArtistDetailModel(
        artist: JiosaavnArtistModel.fromJson(json),
        topSongs: JiosaavnSongModel.listFrom(json['topSongs']),
        albums: JiosaavnAlbumModel.listFrom(json['topAlbums']),
        followerCount: int.tryParse('${json['follower_count'] ?? ''}'),
        bio: _bio(json['bio']),
      );

  /// Artist metadata.
  final JiosaavnArtistModel artist;

  /// Most popular songs.
  final List<JiosaavnSongModel> topSongs;

  /// Top albums.
  final List<JiosaavnAlbumModel> albums;

  /// Follower count.
  final int? followerCount;

  /// Joined, whitespace-collapsed biography (null when empty).
  final String? bio;

  static String? _bio(Object? raw) {
    if (raw is! List) return null;
    final text = raw
        .whereType<String>()
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? null : text;
  }
}
