import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/playback/fake_playback_controller.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  const track = Track(
    id: 'a',
    title: 'A',
    artist: 'X',
    duration: Duration(minutes: 3),
  );

  test('load resolves immediately and reports loading then playing', () async {
    final controller = FakePlaybackController(
      tick: const Duration(milliseconds: 5),
    );
    addTearDown(controller.dispose);

    final statuses = <PlaybackStatus>[];
    final sub = controller.statusStream.listen(statuses.add);

    await controller.load(track).timeout(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(statuses, [PlaybackStatus.loading, PlaybackStatus.playing]);
    expect(controller.isPlaying, isTrue);
    await sub.cancel();
  });

  test('a restored load stays paused at the saved position', () async {
    final controller = FakePlaybackController(
      tick: const Duration(milliseconds: 5),
    );
    addTearDown(controller.dispose);

    final statuses = <PlaybackStatus>[];
    final sub = controller.statusStream.listen(statuses.add);

    await controller.load(
      track,
      startAt: const Duration(seconds: 30),
      autoPlay: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(statuses, [PlaybackStatus.loading, PlaybackStatus.paused]);
    expect(controller.isPlaying, isFalse);
    expect(controller.position.value, const Duration(seconds: 30));
    await sub.cancel();
  });

  test('pause then play emits paused and playing', () async {
    final controller = FakePlaybackController(
      tick: const Duration(milliseconds: 5),
    );
    addTearDown(controller.dispose);

    await controller.load(track);
    final statuses = <PlaybackStatus>[];
    final sub = controller.statusStream.listen(statuses.add);

    await controller.pause();
    await controller.play();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(statuses, [PlaybackStatus.paused, PlaybackStatus.playing]);
    await sub.cancel();
  });

  test('reaching the end emits paused and completes', () async {
    final controller = FakePlaybackController(
      tick: const Duration(milliseconds: 5),
    );
    addTearDown(controller.dispose);

    var completed = false;
    final doneSub = controller.onCompleted.listen((_) => completed = true);
    final statuses = <PlaybackStatus>[];
    final statusSub = controller.statusStream.listen(statuses.add);

    await controller.load(
      const Track(
        id: 's',
        title: 'S',
        artist: 'X',
        duration: Duration(milliseconds: 15),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(completed, isTrue);
    expect(statuses.last, PlaybackStatus.paused);
    expect(controller.isPlaying, isFalse);
    await doneSub.cancel();
    await statusSub.cancel();
  });
}
