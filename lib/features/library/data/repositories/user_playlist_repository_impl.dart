import 'dart:math';

import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/user_playlists_dao.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [UserPlaylistRepository] over the Drift `playlists` / `playlist_songs`
/// tables. Song snapshots are denormalised for offline playback.

/// Drift-backed user-playlist repository.
final class DriftUserPlaylistRepository implements UserPlaylistRepository {
  /// Creates the repository.
  DriftUserPlaylistRepository(this._dao) : _random = Random();

  final UserPlaylistsDao _dao;
  final Random _random;

  @override
  Stream<List<UserPlaylist>> watchAll() =>
      _dao.watchAll().asyncMap(_withCounts);

  @override
  Future<List<UserPlaylist>> all() async => _withCounts(await _dao.all());

  @override
  Future<UserPlaylistDetail?> detail(String id) async {
    final row = await _dao.byId(id);
    if (row == null) return null;
    final songs = await _dao.songs(id);
    return UserPlaylistDetail(
      playlist: _toEntity(row, songs.length),
      songs: songs.map(_toTrack).toList(growable: false),
    );
  }

  @override
  Future<String> create(String name, {String? description}) async {
    final now = DateTime.now();
    final id = _newId();
    await _dao.upsert(
      PlaylistsCompanion.insert(
        id: id,
        name: name.trim(),
        description: Value(description),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<void> rename(String id, String name) =>
      _dao.rename(id, name.trim(), DateTime.now());

  @override
  Future<void> delete(String id) => _dao.delete(id);

  @override
  Future<void> addTrack(String playlistId, Track track) async {
    final position = await _dao.nextPosition(playlistId);
    await _dao.upsertSong(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        album: Value(track.album),
        artUrl: Value(track.artUrl),
        durationMs: Value(track.duration.inMilliseconds),
        streamUrl: Value(track.streamUrl),
        position: position,
      ),
    );
    await _dao.touch(playlistId, DateTime.now());
  }

  @override
  Future<void> removeTrack(String playlistId, String trackId) async {
    await _dao.removeSong(playlistId, trackId);
    await _dao.touch(playlistId, DateTime.now());
  }

  Future<List<UserPlaylist>> _withCounts(List<Playlist> rows) async {
    final result = <UserPlaylist>[];
    for (final row in rows) {
      result.add(_toEntity(row, await _dao.count(row.id)));
    }
    return result;
  }

  UserPlaylist _toEntity(Playlist row, int songCount) => UserPlaylist(
    id: row.id,
    name: row.name,
    description: row.description,
    artUrl: row.artUrl,
    songCount: songCount,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Track _toTrack(PlaylistSong row) => Track(
    id: row.trackId,
    title: row.title,
    artist: row.artist,
    album: row.album,
    artUrl: row.artUrl,
    duration: Duration(milliseconds: row.durationMs),
    streamUrl: row.streamUrl,
  );

  String _newId() =>
      'pl_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 31)}';
}
