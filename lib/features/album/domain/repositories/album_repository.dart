import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

/// Album data contract (domain layer). Search owns discovery; this feature
/// owns the album screen.

/// Reads a full album by id.
abstract interface class AlbumRepository {
  /// Album metadata + ordered songs.
  Future<Either<Failure, AlbumDetail>> album(String id);
}
