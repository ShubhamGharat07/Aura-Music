import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Pauses an in-flight or queued download.

/// Pauses a download.
final class PauseDownload implements UseCase<Unit, String> {
  /// Creates the use case.
  const PauseDownload(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String trackId) =>
      _repository.pause(trackId);
}
