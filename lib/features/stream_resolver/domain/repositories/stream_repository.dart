import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Resolves a [Track] to a playable audio URL through a fallback chain
/// (PRD F01). Presentation depends on this interface only.

/// Track → playable URL contract.
abstract interface class StreamRepository {
  /// Resolves a playable URL for [track], or a [StreamFailure] when every
  /// source in the chain fails.
  Future<Either<Failure, String>> resolve(Track track);
}
