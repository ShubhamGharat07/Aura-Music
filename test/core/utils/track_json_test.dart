import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/utils/track_json.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  const full = Track(
    id: 'audius:1',
    title: 'Neon Horizon',
    artist: 'Aurora Skies',
    album: 'Nightfall',
    artUrl: 'https://cdn/art.jpg',
    duration: Duration(seconds: 215),
    streamUrl: 'https://cdn/stream',
  );

  group('trackToJson / trackFromJson', () {
    test('round-trips a fully populated track', () {
      expect(trackFromJson(trackToJson(full)), full);
    });

    test('round-trips a minimal track with defaults', () {
      const minimal = Track(id: 'a', title: 'T', artist: 'A');
      final decoded = trackFromJson(trackToJson(minimal));
      expect(decoded.id, 'a');
      expect(decoded.album, isNull);
      expect(decoded.artUrl, isNull);
      expect(decoded.streamUrl, isNull);
      expect(decoded.duration, Duration.zero);
    });

    test('defaults missing milliseconds to zero', () {
      final decoded = trackFromJson({'id': 'x', 'title': 'T', 'artist': 'A'});
      expect(decoded.duration, Duration.zero);
    });
  });
}
