import 'dart:convert';

import 'package:aura_music/core/utils/track_json.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// JSON codecs for catalog entities stored in the persistent API cache.
/// Kept in the data layer so domain entities stay framework-free.

/// Encodes a track list.
String encodeTracks(List<Track> tracks) =>
    jsonEncode(tracks.map(trackToJson).toList(growable: false));

/// Decodes a track list encoded by [encodeTracks].
List<Track> decodeTracks(String raw) => _tracks(jsonDecode(raw) as List);

/// Encodes an album list.
String encodeAlbums(List<Album> albums) =>
    jsonEncode(albums.map(_albumToJson).toList(growable: false));

/// Decodes an album list encoded by [encodeAlbums].
List<Album> decodeAlbums(String raw) => _albums(jsonDecode(raw) as List);

/// Encodes an artist list.
String encodeArtists(List<Artist> artists) =>
    jsonEncode(artists.map(_artistToJson).toList(growable: false));

/// Decodes an artist list encoded by [encodeArtists].
List<Artist> decodeArtists(String raw) => _artists(jsonDecode(raw) as List);

/// Encodes a genre list.
String encodeGenres(List<Genre> genres) =>
    jsonEncode(genres.map(_genreToJson).toList(growable: false));

/// Decodes a genre list encoded by [encodeGenres].
List<Genre> decodeGenres(String raw) => _genres(jsonDecode(raw) as List);

/// Encodes an album with its songs.
String encodeAlbumDetail(AlbumDetail detail) => jsonEncode({
  'album': _albumToJson(detail.album),
  'songs': detail.songs.map(trackToJson).toList(growable: false),
});

/// Decodes an album detail encoded by [encodeAlbumDetail].
AlbumDetail decodeAlbumDetail(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return AlbumDetail(
    album: _albumFromJson(json['album'] as Map<String, dynamic>),
    songs: _tracks(json['songs'] as List),
  );
}

/// Encodes an artist page.
String encodeArtistDetail(ArtistDetail detail) => jsonEncode({
  'artist': _artistToJson(detail.artist),
  'top': detail.topSongs.map(trackToJson).toList(growable: false),
  'albums': detail.albums.map(_albumToJson).toList(growable: false),
  'followers': detail.followerCount,
  'bio': detail.bio,
});

/// Decodes an artist page encoded by [encodeArtistDetail].
ArtistDetail decodeArtistDetail(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return ArtistDetail(
    artist: _artistFromJson(json['artist'] as Map<String, dynamic>),
    topSongs: _tracks(json['top'] as List),
    albums: _albums(json['albums'] as List),
    followerCount: (json['followers'] as num?)?.toInt(),
    bio: json['bio'] as String?,
  );
}

/// Encodes a playlist with its songs.
String encodePlaylistDetail(PlaylistDetail detail) => jsonEncode({
  'playlist': _playlistToJson(detail.playlist),
  'songs': detail.songs.map(trackToJson).toList(growable: false),
});

/// Decodes a playlist detail encoded by [encodePlaylistDetail].
PlaylistDetail decodePlaylistDetail(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return PlaylistDetail(
    playlist: _playlistFromJson(json['playlist'] as Map<String, dynamic>),
    songs: _tracks(json['songs'] as List),
  );
}

List<Track> _tracks(List<dynamic> rows) => rows
    .map((row) => trackFromJson(row as Map<String, dynamic>))
    .toList(growable: false);

List<Album> _albums(List<dynamic> rows) => rows
    .map((row) => _albumFromJson(row as Map<String, dynamic>))
    .toList(growable: false);

List<Artist> _artists(List<dynamic> rows) => rows
    .map((row) => _artistFromJson(row as Map<String, dynamic>))
    .toList(growable: false);

List<Genre> _genres(List<dynamic> rows) => rows
    .map((row) => _genreFromJson(row as Map<String, dynamic>))
    .toList(growable: false);

Map<String, dynamic> _albumToJson(Album album) => {
  'id': album.id,
  'title': album.title,
  'artist': album.artist,
  'art': album.artUrl,
  'year': album.year,
  'songs': album.songCount,
  'lang': album.language,
};

Album _albumFromJson(Map<String, dynamic> json) => Album(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  artUrl: json['art'] as String?,
  year: (json['year'] as num?)?.toInt(),
  songCount: (json['songs'] as num?)?.toInt(),
  language: json['lang'] as String?,
);

Map<String, dynamic> _artistToJson(Artist artist) => {
  'id': artist.id,
  'name': artist.name,
  'image': artist.imageUrl,
  'role': artist.role,
};

Artist _artistFromJson(Map<String, dynamic> json) => Artist(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['image'] as String?,
  role: json['role'] as String?,
);

Map<String, dynamic> _genreToJson(Genre genre) => {
  'id': genre.id,
  'name': genre.name,
  'art': genre.artUrl,
};

Genre _genreFromJson(Map<String, dynamic> json) => Genre(
  id: json['id'] as String,
  name: json['name'] as String,
  artUrl: json['art'] as String?,
);

Map<String, dynamic> _playlistToJson(Playlist playlist) => {
  'id': playlist.id,
  'title': playlist.title,
  'art': playlist.artUrl,
  'songs': playlist.songCount,
  'subtitle': playlist.subtitle,
};

Playlist _playlistFromJson(Map<String, dynamic> json) => Playlist(
  id: json['id'] as String,
  title: json['title'] as String,
  artUrl: json['art'] as String?,
  songCount: (json['songs'] as num?)?.toInt(),
  subtitle: json['subtitle'] as String?,
);
