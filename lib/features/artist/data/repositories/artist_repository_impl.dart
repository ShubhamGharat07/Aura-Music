import 'dart:async';

import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/error/guard.dart';
import 'package:aura_music/features/artist/domain/repositories/artist_repository.dart';
import 'package:aura_music/features/catalog/data/cache/catalog_cache_codec.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

/// [ArtistRepository] implementation over the shared JioSaavn client. Successful
/// artist pages are snapshotted to SQLite so reopening one skips the API call.

/// JioSaavn-backed artist repository.
final class ArtistRepositoryImpl implements ArtistRepository {
  /// Creates the repository.
  const ArtistRepositoryImpl(this._remote, {PersistentCache? cache})
    : _cache = cache;

  final JiosaavnRemoteDataSource _remote;
  final PersistentCache? _cache;

  static const Duration _ttl = Duration(hours: 12);

  @override
  Future<Either<Failure, ArtistDetail>> artist(String id) async {
    final key = 'artist:$id';
    final cache = _cache;
    if (cache != null) {
      final cached = await cache.read(
        key,
        ttl: _ttl,
        decode: decodeArtistDetail,
      );
      if (cached != null) return Right(cached);
    }
    final result = await guardRemote(() => _remote.artist(id));
    result.fold((_) {}, (value) {
      if (cache != null) {
        unawaited(cache.write(key, encodeArtistDetail(value)));
      }
    });
    return result;
  }
}
