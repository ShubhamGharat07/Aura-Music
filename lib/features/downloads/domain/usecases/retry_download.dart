import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Retries a failed download.

/// Retries a download.
final class RetryDownload implements UseCase<Unit, String> {
  /// Creates the use case.
  const RetryDownload(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String trackId) =>
      _repository.retry(trackId);
}
