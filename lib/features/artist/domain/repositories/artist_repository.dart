import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

/// Artist data contract (domain layer).

/// Reads a full artist page by id.
abstract interface class ArtistRepository {
  /// Artist metadata + top songs + albums.
  Future<Either<Failure, ArtistDetail>> artist(String id);
}
