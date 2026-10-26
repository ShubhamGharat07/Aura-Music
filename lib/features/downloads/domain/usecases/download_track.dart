import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Downloads a track for offline playback.

/// Enqueues a track for offline download.
final class DownloadTrack implements UseCase<Unit, Track> {
  /// Creates the use case.
  const DownloadTrack(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(Track track) => _repository.enqueue(track);
}
