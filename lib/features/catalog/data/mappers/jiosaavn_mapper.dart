import 'package:aura_music/core/utils/des_ecb.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_album_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_artist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_genre_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_playlist_model.dart';
import 'package:aura_music/features/catalog/data/models/jiosaavn_song_model.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Maps JioSaavn DTOs to domain entities (PRD 5.1 Mapper layer). Data layer
/// only: decrypts media URLs, upgrades artwork, normalises text.

/// JioSaavn model → entity mapper.
final class JiosaavnMapper {
  /// Creates the mapper.
  const JiosaavnMapper();

  /// Public CDN symmetric key used by JioSaavn (`DES`/`ECB`).
  static const String _desKey = '38346591';

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _qualitySuffix = RegExp(r'_(48|96|160|320)\.');

  /// Maps a song model to a playable [Track].
  Track track(JiosaavnSongModel model) {
    final album = _text(model.info.album);
    return Track(
      id: 'jiosaavn:${model.id}',
      title: _title(model.rawTitle),
      artist: _artist(model.info),
      album: album.isEmpty ? null : album,
      artUrl: artwork(model.imageUrl),
      duration: Duration(seconds: model.info.durationSeconds),
      streamUrl: streamUrl(model),
      playCount: model.playCount,
    );
  }

  /// Maps an album model to an [Album].
  Album album(JiosaavnAlbumModel model) {
    final names = _names(model.artistNames);
    final language = _text(model.language);
    return Album(
      id: model.id,
      title: _title(model.rawTitle),
      artist: names.isNotEmpty ? names : _fallbackArtist(model.subtitle),
      artUrl: artwork(model.imageUrl),
      year: model.resolvedYear,
      songCount: model.songCount,
      language: language.isEmpty ? null : language,
    );
  }

  /// Maps an artist model to an [Artist].
  Artist artist(JiosaavnArtistModel model) {
    final role = _text(model.role);
    return Artist(
      id: model.id,
      name: _title(model.rawName),
      imageUrl: artwork(model.imageUrl),
      role: role.isEmpty ? null : role,
    );
  }

  /// Maps a playlist model to a [Playlist].
  Playlist playlist(JiosaavnPlaylistModel model) {
    final subtitle = _text(model.subtitle);
    return Playlist(
      id: model.id,
      title: _title(model.rawTitle),
      artUrl: artwork(model.imageUrl),
      songCount: model.songCount,
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
  }

  /// Maps a browse channel model to a [Genre].
  Genre genre(JiosaavnGenreModel model) => Genre(
    id: model.id,
    name: model.rawTitle,
    artUrl: artwork(model.imageUrl),
  );

  /// Maps an album-detail model to an [AlbumDetail].
  AlbumDetail albumDetail(JiosaavnAlbumDetailModel model) => AlbumDetail(
    album: album(model.album),
    songs: model.songs.map(track).toList(growable: false),
  );

  /// Maps a playlist-detail model to a [PlaylistDetail].
  PlaylistDetail playlistDetail(JiosaavnPlaylistDetailModel model) =>
      PlaylistDetail(
        playlist: playlist(model.playlist),
        songs: model.songs.map(track).toList(growable: false),
      );

  /// Maps an artist-detail model to an [ArtistDetail].
  ArtistDetail artistDetail(JiosaavnArtistDetailModel model) => ArtistDetail(
    artist: artist(model.artist),
    topSongs: model.topSongs.map(track).toList(growable: false),
    albums: model.albums.map(album).toList(growable: false),
    followerCount: model.followerCount,
    bio: model.bio,
  );

  /// Expands a song's `more_info` block to a 320 (or 160) kbps stream URL.
  String? streamUrl(JiosaavnSongModel model) => _streamUrl(
    model.info.encryptedMediaUrl,
    prefer320: model.info.prefers320,
  );

  /// Upgrades `http` → `https` and 150 px → 500 px artwork.
  String? artwork(String? link) {
    if (link == null || link.isEmpty) return null;
    return link
        .replaceFirst('http://', 'https://')
        .replaceFirst('150x150', '500x500');
  }

  String _title(String? raw) {
    final value = _text(raw);
    return value.isEmpty ? 'Unknown' : value;
  }

  String _artist(JiosaavnSongInfoModel info) {
    final names = _names(info.artistNames);
    if (names.isNotEmpty) return names;
    return _fallbackArtist(info.primaryArtists ?? info.music);
  }

  String _names(List<String> raw) =>
      raw.map(_text).where((name) => name.isNotEmpty).join(', ');

  String _fallbackArtist(String? raw) {
    final value = _text(raw);
    return value.isEmpty ? 'Unknown artist' : value;
  }

  String? _streamUrl(String? encrypted, {bool prefer320 = true}) {
    if (encrypted == null || encrypted.isEmpty) return null;
    final decrypted = DesEcb.decryptBase64ToString(encrypted, _desKey);
    if (decrypted.isEmpty) return null;
    final quality = prefer320 ? '320' : '160';
    return decrypted
        .replaceFirst('http://', 'https://')
        .replaceFirst(_qualitySuffix, '_$quality.');
  }

  String _text(String? value) {
    if (value == null || value.isEmpty) return '';
    var text = value;
    if (text.contains('&')) {
      text = text
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');
    }
    return text.replaceAll(_whitespace, ' ').trim();
  }
}
