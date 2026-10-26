import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/entities/download_summary.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  Download make(String id, DownloadStatus status, {int bytes = 0}) => Download(
    track: Track(id: id, title: 'T$id', artist: 'A'),
    status: status,
    bytesDownloaded: bytes,
  );

  group('DownloadSummary.of', () {
    test('is empty for no downloads', () {
      final summary = DownloadSummary.of(const []);
      expect(summary.total, 0);
      expect(summary.bytesUsed, 0);
      expect(summary.completed, 0);
    });

    test('counts statuses and sums completed bytes only', () {
      final summary = DownloadSummary.of([
        make('a', DownloadStatus.completed, bytes: 100),
        make('b', DownloadStatus.completed, bytes: 50),
        make('c', DownloadStatus.downloading, bytes: 25),
        make('d', DownloadStatus.queued),
        make('e', DownloadStatus.paused),
        make('f', DownloadStatus.failed),
      ]);
      expect(summary.total, 6);
      expect(summary.completed, 2);
      expect(summary.inProgress, 3);
      expect(summary.failed, 1);
      expect(summary.bytesUsed, 150);
    });
  });
}
