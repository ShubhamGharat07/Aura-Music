import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Resolves the local file for a downloaded track (offline playback).

/// Returns the local file path for a track, or null when not downloaded.
final class GetDownloadedFile implements UseCase<String?, String> {
  /// Creates the use case.
  const GetDownloadedFile(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, String?>> call(String trackId) =>
      _repository.localFileFor(trackId);
}
