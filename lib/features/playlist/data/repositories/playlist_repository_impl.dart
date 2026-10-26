import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/features/catalog/data/cache/catalog_cache_codec.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/playlist/domain/repositories/playlist_repository.dart';

/// [PlaylistRepository] implementation over the shared JioSaavn client.
/// Successful playlists are snapshotted to SQLite so reopening one skips the
/// API call.

/// JioSaavn-backed playlist repository.
final class PlaylistRepositoryImpl implements PlaylistRepository {
  /// Creates the repository.
  const PlaylistRepositoryImpl(this._remote, {PersistentCache? cache})
    : _cache = cache;

  final JiosaavnRemoteDataSource _remote;
  final PersistentCache? _cache;

  static const Duration _ttl = Duration(hours: 12);

  @override
  Future<Either<Failure, PlaylistDetail>> playlist(String id) async {
    final key = 'playlist:$id';
    final cache = _cache;
    if (cache != null) {
      final cached = await cache.read(
        key,
        ttl: _ttl,
        decode: decodePlaylistDetail,
      );
      if (cached != null) return Right(cached);
    }
    final result = await guardRemote(() => _remote.playlist(id));
    result.fold((_) {}, (value) {
      if (cache != null) {
        unawaited(cache.write(key, encodePlaylistDetail(value)));
      }
    });
    return result;
  }
}
