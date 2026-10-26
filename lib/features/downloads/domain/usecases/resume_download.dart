import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Resumes a paused download from its byte offset.

/// Resumes a download.
final class ResumeDownload implements UseCase<Unit, String> {
  /// Creates the use case.
  const ResumeDownload(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String trackId) =>
      _repository.resume(trackId);
}
