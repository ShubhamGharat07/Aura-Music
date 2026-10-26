// JioSaavn song DTOs (PRD 5.1 data layer). These types mirror the raw JSON
// shape only; all normalisation (artwork upgrade, URL decryption, HTML
// entities) happens in `JiosaavnMapper`.

/// The `more_info` block attached to songs and albums.
final class JiosaavnSongInfoModel {
  /// Creates a song info model.
  const JiosaavnSongInfoModel({
    this.durationSeconds = 0,
    this.album,
    this.encryptedMediaUrl,
    this.prefers320 = true,
    this.primaryArtists,
    this.music,
    this.artistNames = const <String>[],
  });

  /// Parses a `more_info` object; missing or malformed input is tolerated.
  factory JiosaavnSongInfoModel.fromJson(Object? raw) {
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return JiosaavnSongInfoModel(
      durationSeconds: int.tryParse('${json['duration'] ?? ''}') ?? 0,
      album: json['album'] as String?,
      encryptedMediaUrl: json['encrypted_media_url'] as String?,
      prefers320: json['320kbps']?.toString() != 'false',
      primaryArtists: json['primary_artists'] as String?,
      music: json['music'] as String?,
      artistNames: primaryArtistNames(json['artistMap']),
    );
  }

  /// Length in seconds (0 when absent).
  final int durationSeconds;

  /// Album name.
  final String? album;

  /// Encrypted `DES`/`ECB` media URL (decrypted by the mapper).
  final String? encryptedMediaUrl;

  /// Whether a 320 kbps rendition is available.
  final bool prefers320;

  /// Comma-joined primary artists (fallback when `artistMap` is missing).
  final String? primaryArtists;

  /// Music director (last-resort artist fallback).
  final String? music;

  /// Artist names pulled from `artistMap.primary_artists`.
  final List<String> artistNames;

  /// Reads the primary artist names out of an `artistMap` node.
  static List<String> primaryArtistNames(Object? artistMap) {
    if (artistMap is! Map<String, dynamic>) return const <String>[];
    final artists = artistMap['primary_artists'];
    if (artists is! List) return const <String>[];
    return artists
        .whereType<Map<String, dynamic>>()
        .map((artist) => artist['name'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }
}

/// A song node from a JioSaavn response.
final class JiosaavnSongModel {
  /// Creates a song model.
  const JiosaavnSongModel({
    required this.id,
    this.title,
    this.name,
    this.song,
    this.imageUrl,
    this.subtitle,
    this.playCount = 0,
    this.info = const JiosaavnSongInfoModel(),
  });

  /// Parses a song JSON object.
  factory JiosaavnSongModel.fromJson(Map<String, dynamic> json) =>
      JiosaavnSongModel(
        id: '${json['id'] ?? ''}',
        title: json['title'] as String?,
        name: json['name'] as String?,
        song: json['song'] as String?,
        imageUrl: json['image'] as String?,
        subtitle: json['subtitle'] as String?,
        playCount: int.tryParse('${json['play_count'] ?? ''}') ?? 0,
        info: JiosaavnSongInfoModel.fromJson(json['more_info']),
      );

  /// Parses a JSON array of song objects (missing / malformed tolerated).
  static List<JiosaavnSongModel> listFrom(Object? raw) =>
      (raw is List ? raw : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(JiosaavnSongModel.fromJson)
          .toList(growable: false);

  /// Raw JioSaavn id (no prefix).
  final String id;

  /// Title variants (whichever the endpoint provides).
  final String? title;

  /// Name variant (albums / artists).
  final String? name;

  /// Song variant (playlist rows).
  final String? song;

  /// Artwork URL (`150x150`).
  final String? imageUrl;

  /// Secondary line.
  final String? subtitle;

  /// Lifetime play count (`play_count`), 0 when absent.
  final int playCount;

  /// `more_info` block.
  final JiosaavnSongInfoModel info;

  /// Best available raw title (`title` → `name` → `song`).
  String? get rawTitle => title ?? name ?? song;
}
