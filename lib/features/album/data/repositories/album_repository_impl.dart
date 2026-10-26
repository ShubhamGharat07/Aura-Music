import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/catalog/data/cache/catalog_cache_codec.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

/// [AlbumRepository] implementation over the shared JioSaavn client. Successful
/// album payloads are snapshotted to SQLite so reopening the same album does
/// not repeat the API call.

/// JioSaavn-backed album repository.
final class AlbumRepositoryImpl implements AlbumRepository {
  /// Creates the repository.
  const AlbumRepositoryImpl(this._remote, {PersistentCache? cache})
    : _cache = cache;

  final JiosaavnRemoteDataSource _remote;
  final PersistentCache? _cache;

  static const Duration _ttl = Duration(hours: 12);

  @override
  Future<Either<Failure, AlbumDetail>> album(String id) async {
    final key = 'album:$id';
    final cache = _cache;
    if (cache != null) {
      final cached = await cache.read(
        key,
        ttl: _ttl,
        decode: decodeAlbumDetail,
      );
      if (cached != null) return Right(cached);
    }
    final result = await guardRemote(() => _remote.album(id));
    result.fold((_) {}, (value) {
      if (cache != null) {
        unawaited(cache.write(key, encodeAlbumDetail(value)));
      }
    });
    return result;
  }
}
