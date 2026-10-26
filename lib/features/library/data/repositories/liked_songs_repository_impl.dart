import 'package:drift/drift.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/liked_songs_dao.dart';
import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// [LikedSongsRepository] over the Drift `liked_songs` table.

/// Drift-backed liked songs repository.
final class DriftLikedSongsRepository implements LikedSongsRepository {
  /// Creates the repository.
  const DriftLikedSongsRepository(this._dao);

  final LikedSongsDao _dao;

  @override
  Stream<List<Track>> watchLiked() =>
      _dao.watchAll().map((rows) => rows.map(_toTrack).toList(growable: false));

  @override
  Future<List<Track>> all() async =>
      (await _dao.all()).map(_toTrack).toList(growable: false);

  @override
  Future<bool> isLiked(String trackId) => _dao.contains(trackId);

  @override
  Future<bool> toggle(Track track) async {
    if (await _dao.contains(track.id)) {
      await _dao.delete(track.id);
      return false;
    }
    await _dao.upsert(_companion(track));
    return true;
  }

  @override
  Future<void> remove(String trackId) => _dao.delete(trackId);

  @override
  Future<void> clear() => _dao.clear();

  Track _toTrack(LikedSong row) => Track(
    id: row.trackId,
    title: row.title,
    artist: row.artist,
    album: row.album,
    artUrl: row.artUrl,
    duration: Duration(milliseconds: row.durationMs),
    streamUrl: row.streamUrl,
  );

  LikedSongsCompanion _companion(Track track) => LikedSongsCompanion.insert(
    trackId: track.id,
    title: track.title,
    artist: track.artist,
    album: Value(track.album),
    artUrl: Value(track.artUrl),
    durationMs: Value(track.duration.inMilliseconds),
    streamUrl: Value(track.streamUrl),
    likedAt: DateTime.now().millisecondsSinceEpoch,
  );
}
