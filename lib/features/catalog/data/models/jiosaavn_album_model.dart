import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';

/// JioSaavn album DTOs (PRD 5.1 data layer).

/// An album node (search result or `content.getAlbumDetails`).
final class JiosaavnAlbumModel {
  /// Creates an album model.
  const JiosaavnAlbumModel({
    required this.id,
    this.title,
    this.name,
    this.imageUrl,
    this.subtitle,
    this.year,
    this.songCount,
    this.releaseYear,
    this.language,
    this.kind,
    this.artistNames = const <String>[],
  });

  /// Parses an album JSON object.
  factory JiosaavnAlbumModel.fromJson(Map<String, dynamic> json) {
    final info = json['more_info'] is Map<String, dynamic>
        ? json['more_info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return JiosaavnAlbumModel(
      id: '${json['id'] ?? ''}',
      title: json['title'] as String?,
      name: json['name'] as String?,
      imageUrl: json['image'] as String?,
      subtitle: json['subtitle'] as String?,
      year: int.tryParse('${json['year'] ?? ''}'),
      songCount: int.tryParse(
        '${info['song_count'] ?? json['list_count'] ?? ''}',
      ),
      releaseYear: int.tryParse(
        '${info['release_date'] ?? ''}'.split('-').first,
      ),
      language: json['language'] as String?,
      kind: json['type'] as String?,
      artistNames: JiosaavnSongInfoModel.primaryArtistNames(info['artistMap']),
    );
  }

  /// Parses a JSON array of album objects (missing / malformed tolerated).
  static List<JiosaavnAlbumModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnAlbumModel.fromJson)
          .toList(growable: false);

  /// Raw JioSaavn id.
  final String id;

  /// Title variants.
  final String? title;

  /// Name variant.
  final String? name;

  /// Artwork URL (`150x150`).
  final String? imageUrl;

  /// Secondary line (artist list as served).
  final String? subtitle;

  /// Release year from the top-level `year` field.
  final int? year;

  /// Song count.
  final int? songCount;

  /// Release year parsed from `more_info.release_date`.
  final int? releaseYear;

  /// Catalog language code from the top-level `language` field.
  final String? language;

  /// Raw `type` field (`album`, `song`, `playlist`).
  final String? kind;

  /// Artist names from `more_info.artistMap.primary_artists`.
  final List<String> artistNames;

  /// Best available raw title (`title` → `name`).
  String? get rawTitle => title ?? name;

  /// Release year, preferring `more_info.release_date` over the `year` field.
  int? get resolvedYear => releaseYear ?? year;

  /// True for a real album node.
  ///
  /// The "new releases" and trending feeds mix albums with singles and
  /// playlists, and only the album nodes carry an id that
  /// `content.getAlbumDetails` resolves — so this is the filter that keeps the
  /// grids tappable.
  bool get isAlbum => kind == 'album';
}

/// `content.getAlbumDetails` response: album metadata plus ordered songs.
final class JiosaavnAlbumDetailModel {
  /// Creates an album detail model.
  const JiosaavnAlbumDetailModel({
    required this.album,
    this.songs = const <JiosaavnSongModel>[],
  });

  /// Parses the album-detail JSON object.
  factory JiosaavnAlbumDetailModel.fromJson(Map<String, dynamic> json) =>
      JiosaavnAlbumDetailModel(
        album: JiosaavnAlbumModel.fromJson(json),
        songs: JiosaavnSongModel.listFrom(json['list']),
      );

  /// Album metadata.
  final JiosaavnAlbumModel album;

  /// Ordered album songs.
  final List<JiosaavnSongModel> songs;
}
