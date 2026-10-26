import 'package:aura_music/features/player/domain/entities/track.dart';

/// Minimal JSON codec for [Track] used by local persistence (SharedPreferences).
/// Kept out of the domain entity so the entity stays pure Dart.

/// Encodes a [Track] to a JSON map.
Map<String, dynamic> trackToJson(Track track) => {
  'id': track.id,
  'title': track.title,
  'artist': track.artist,
  'album': track.album,
  'art': track.artUrl,
  'ms': track.duration.inMilliseconds,
  'stream': track.streamUrl,
};

/// Decodes a [Track] from a JSON map.
Track trackFromJson(Map<String, dynamic> json) => Track(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
  album: json['album'] as String?,
  artUrl: json['art'] as String?,
  duration: Duration(milliseconds: (json['ms'] as num?)?.toInt() ?? 0),
  streamUrl: json['stream'] as String?,
);
