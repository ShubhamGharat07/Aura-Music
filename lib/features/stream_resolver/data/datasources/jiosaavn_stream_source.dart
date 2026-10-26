import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_source.dart';

/// JioSaavn-backed [StreamSource].
///
/// Always asks the catalog for a fresh CDN URL: catalog/restored URLs expire
/// after a few hours and a stale one is the main cause of "play does nothing".
/// Non-JioSaavn ids (e.g. `youtube:`) keep their inline URL so later sources in
/// the chain can handle them.

/// First source in the chain.
final class JiosaavnStreamSource implements StreamSource {
  /// Creates the source.
  const JiosaavnStreamSource(this._client);

  final JiosaavnRemoteDataSource _client;

  /// JioSaavn track-id prefix.
  static const String _prefix = 'jiosaavn:';

  @override
  String get name => 'jiosaavn';

  @override
  Future<String?> resolve(Track track) async {
    final id = _id(track.id);
    if (id == null) return track.streamUrl;
    return _client.streamUrlFor(id);
  }

  String? _id(String trackId) =>
      trackId.startsWith(_prefix) ? trackId.substring(_prefix.length) : null;
}
