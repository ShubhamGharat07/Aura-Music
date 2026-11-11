import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/playback/just_audio_playback_controller.dart';

void main() {
  group('JustAudioPlaybackController.lowerQualityUrl', () {
    test('steps 320 → 160 → 96 and then stops', () {
      const url = 'https://aac.saavncdn.com/9/song_320.mp4';

      final at160 = JustAudioPlaybackController.lowerQualityUrl(url);
      expect(at160, 'https://aac.saavncdn.com/9/song_160.mp4');

      final at96 = JustAudioPlaybackController.lowerQualityUrl(at160!);
      expect(at96, 'https://aac.saavncdn.com/9/song_96.mp4');

      expect(JustAudioPlaybackController.lowerQualityUrl(at96!), isNull);
    });

    test('returns null for a URL without a quality rendition', () {
      expect(
        JustAudioPlaybackController.lowerQualityUrl(
          'https://cdn.example.com/live.m3u8',
        ),
        isNull,
      );
    });
  });
}
