import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/features/player/data/repositories/prefs_playback_session_repository.dart';
import 'package:aura_music/features/player/domain/entities/playback_session.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const tracks = [
    Track(
      id: 'a',
      title: 'A',
      artist: 'X',
      duration: Duration(minutes: 3),
      streamUrl: 'https://s/a',
    ),
    Track(id: 'b', title: 'B', artist: 'Y', duration: Duration(minutes: 4)),
  ];

  late SharedPreferences prefs;
  late PrefsPlaybackSessionRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = PrefsPlaybackSessionRepository(prefs);
  });

  test('returns null when nothing was ever saved', () async {
    expect(await repository.read(), isNull);
  });

  test('round-trips queue, index, position, shuffle and repeat', () async {
    await repository.write(
      const PlaybackSession(
        queue: tracks,
        index: 1,
        position: Duration(seconds: 42),
        shuffle: true,
        repeat: RepeatMode.all,
      ),
    );

    final session = await repository.read();

    expect(session, isNotNull);
    expect(session!.queue, tracks);
    expect(session.index, 1);
    expect(session.position, const Duration(seconds: 42));
    expect(session.shuffle, isTrue);
    expect(session.repeat, RepeatMode.all);
  });

  test('an empty queue is not persisted', () async {
    await repository.write(const PlaybackSession(queue: [], index: 0));

    expect(await repository.read(), isNull);
    expect(prefs.getString(PrefsPlaybackSessionRepository.key), isNull);
  });

  test('an index past the end clamps to the last track', () async {
    await repository.write(const PlaybackSession(queue: tracks, index: 9));

    final session = await repository.read();

    expect(session!.current, tracks.last);
  });

  test('a corrupt payload decodes to null instead of throwing', () async {
    await prefs.setString(PrefsPlaybackSessionRepository.key, '{not json');

    expect(await repository.read(), isNull);
  });

  test('a payload without tracks decodes to null', () async {
    await prefs.setString(PrefsPlaybackSessionRepository.key, '{"q":[],"i":0}');

    expect(await repository.read(), isNull);
  });

  test('clear removes the stored session', () async {
    await repository.write(const PlaybackSession(queue: tracks, index: 0));

    await repository.clear();

    expect(await repository.read(), isNull);
  });
}
