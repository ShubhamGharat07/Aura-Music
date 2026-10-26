import 'package:aura_music/features/player/domain/entities/track.dart';

/// A single audio-stream provider in the stream-resolver fallback chain
/// (PRD 5.2). Implementations are interchangeable and registered in DI, so
/// adding a new provider never changes existing code (Open/Closed).

/// One interchangeable stream provider.
abstract interface class StreamSource {
  /// Provider id, used for diagnostics and logging.
  String get name;

  /// Resolves a playable URL for [track], or null when this source cannot.
  Future<String?> resolve(Track track);
}
