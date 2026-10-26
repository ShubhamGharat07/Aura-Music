import 'package:flutter_test/flutter_test.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  const track = Track(
    id: 'audius:1',
    title: 'Neon Horizon',
    artist: 'Aurora Skies',
  );

  test('progress reflects bytes and clamps', () {
    const half = Download(
      track: track,
      status: DownloadStatus.downloading,
      bytesDownloaded: 50,
      totalBytes: 100,
    );
    expect(half.progress, 0.5);

    const over = Download(
      track: track,
      status: DownloadStatus.downloading,
      bytesDownloaded: 120,
      totalBytes: 100,
    );
    expect(over.progress, 1.0);
  });

  test('progress is 1 when completed even without byte counts', () {
    const done = Download(track: track, status: DownloadStatus.completed);
    expect(done.progress, 1.0);
  });

  test('isComplete requires completed status and a file path', () {
    const noPath = Download(track: track, status: DownloadStatus.completed);
    expect(noPath.isComplete, isFalse);
    expect(
      const Download(
        track: track,
        status: DownloadStatus.completed,
        filePath: '/x',
      ).isComplete,
      isTrue,
    );
  });

  test('isActive covers in-flight statuses', () {
    for (final status in [
      DownloadStatus.queued,
      DownloadStatus.downloading,
      DownloadStatus.paused,
    ]) {
      expect(Download(track: track, status: status).isActive, isTrue);
    }
    expect(
      const Download(track: track, status: DownloadStatus.failed).isActive,
      isFalse,
    );
  });
}
