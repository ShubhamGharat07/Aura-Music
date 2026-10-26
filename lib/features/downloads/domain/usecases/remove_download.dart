import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Removes a downloaded track and its file.

/// Deletes a download.
final class RemoveDownload implements UseCase<Unit, String> {
  /// Creates the use case.
  const RemoveDownload(this._repository);

  final DownloadsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String trackId) =>
      _repository.remove(trackId);
}
