import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';

/// Reactive download list for the Downloads screen.

/// Streams the download list.
final class WatchDownloads {
  /// Creates the use case.
  const WatchDownloads(this._repository);

  final DownloadsRepository _repository;

  /// Emits the download list on every change.
  Stream<List<Download>> call() => _repository.watchAll();
}
