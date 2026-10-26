import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/downloads/domain/usecases/download_track.dart';
import 'package:aura_music/features/downloads/domain/usecases/pause_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/remove_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/resume_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/retry_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/watch_downloads.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/settings/presentation/pages/storage_settings_page.dart';

import '../../helpers/pump_app.dart';

final class _MockDownloadsRepository extends Mock
    implements DownloadsRepository {}

void main() {
  late _MockDownloadsRepository repository;
  late StreamController<List<Download>> controller;
  late DownloadsCubit cubit;

  setUp(() {
    repository = _MockDownloadsRepository();
    controller = StreamController<List<Download>>.broadcast();
    when(() => repository.watchAll()).thenAnswer((_) => controller.stream);
    cubit = DownloadsCubit(
      WatchDownloads(repository),
      DownloadTrack(repository),
      RemoveDownload(repository),
      PauseDownload(repository),
      ResumeDownload(repository),
      RetryDownload(repository),
    );
    addTearDown(cubit.close);
    addTearDown(controller.close);
  });

  Widget host() => BlocProvider<DownloadsCubit>.value(
    value: cubit,
    child: const StorageSettingsPage(),
  );

  testWidgets('renders the offline usage summary from the downloads cubit', (
    tester,
  ) async {
    controller.add(const [
      Download(
        track: Track(id: 'a', title: 'A', artist: 'X'),
        status: DownloadStatus.completed,
        filePath: '/a',
        bytesDownloaded: 1024 * 1024 * 3,
      ),
      Download(
        track: Track(id: 'b', title: 'B', artist: 'Y'),
        status: DownloadStatus.downloading,
        bytesDownloaded: 1000,
        totalBytes: 2000,
      ),
    ]);

    await pumpApp(tester, host());
    await tester.pump();

    expect(find.text('1 of 2 tracks available offline'), findsOneWidget);
    expect(find.text('3 MB used on this device'), findsOneWidget);
    expect(find.text('1 download(s) in progress'), findsOneWidget);
  });

  testWidgets('disables removal when there is nothing downloaded', (
    tester,
  ) async {
    controller.add(const []);

    await pumpApp(tester, host());
    await tester.pump();

    expect(find.text('0 of 0 tracks available offline'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Remove all downloads'),
    );
    expect(tile.enabled, isFalse);
  });
}
