import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Loads the "Because you listened to [artist]" section (PRD S03) from the
/// artist the user most recently played.

/// Returns tracks similar to [artist].
final class GetArtistRadio implements UseCase<List<Track>, String> {
  /// Creates the use case.
  const GetArtistRadio(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, List<Track>>> call(String artist) =>
      _repository.byArtist(artist);
}
