import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';

/// Playlist data contract (domain layer).

/// Reads a full playlist by id.
abstract interface class PlaylistRepository {
  /// Playlist metadata + ordered songs.
  Future<Either<Failure, PlaylistDetail>> playlist(String id);
}
