import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/ui/app_spinner.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
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
import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';
import 'package:aura_music/features/search/presentation/widgets/search_idle_view.dart';
import 'package:aura_music/features/search/presentation/widgets/search_results_view.dart';

import '../../../helpers/pump_app.dart';

final class _MockDownloadsRepository extends Mock
    implements DownloadsRepository {}

void main() {
  late StreamController<List<Download>> controller;
  late DownloadsCubit downloads;

  setUp(() {
    final repository = _MockDownloadsRepository();
    controller = StreamController<List<Download>>.broadcast();
    when(() => repository.watchAll()).thenAnswer((_) => controller.stream);
    downloads = DownloadsCubit(
      WatchDownloads(repository),
      DownloadTrack(repository),
      RemoveDownload(repository),
      PauseDownload(repository),
      ResumeDownload(repository),
      RetryDownload(repository),
    );
    addTearDown(downloads.close);
    addTearDown(controller.close);
  });

  Widget host(Widget child) =>
      BlocProvider<DownloadsCubit>.value(value: downloads, child: child);

  testWidgets('idle view shows recent terms and ranked suggestions', (
    tester,
  ) async {
    await pumpApp(
      tester,
      host(
        SearchIdleView(
          recent: const <String>['neon'],
          onTermTap: (_) {},
          onClearRecent: () {},
          onRemoveTerm: (_) {},
          browse: const <Track>[
            Track(
              id: 'a',
              title: 'Babydoll',
              artist: 'Jamie Miller',
              playCount: 833000,
            ),
          ],
          browseStatus: BrowseStatus.ready,
          browseError: null,
          onPlay: (_, _) {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('neon'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Babydoll'), findsOneWidget);
    expect(find.text('#1  833k plays'), findsOneWidget);
  });

  testWidgets('idle view shows a spinner while suggestions load', (
    tester,
  ) async {
    await pumpApp(
      tester,
      host(
        SearchIdleView(
          recent: const <String>[],
          onTermTap: (_) {},
          onClearRecent: () {},
          onRemoveTerm: (_) {},
          browse: const <Track>[],
          browseStatus: BrowseStatus.loading,
          browseError: null,
          onPlay: (_, _) {},
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.byType(AppSpinner), findsOneWidget);
  });

  testWidgets('results view shows only the selected filter section', (
    tester,
  ) async {
    const state = SearchState(
      status: SearchStatus.ready,
      query: 'neon',
      filter: SearchFilter.songs,
      results: SearchResults(
        songs: <Track>[Track(id: 'a', title: 'Song A', artist: 'X')],
        albums: <Album>[Album(id: 'b', title: 'Album B', artist: 'Y')],
      ),
    );

    await pumpApp(
      tester,
      host(SearchResultsView(state: state, onPlay: (_, _) {})),
    );

    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Albums'), findsNothing);
    expect(find.text('Album B'), findsNothing);
  });

  testWidgets('results view shows an empty state when nothing matched', (
    tester,
  ) async {
    const state = SearchState(status: SearchStatus.ready, query: 'zzz');

    await pumpApp(
      tester,
      host(SearchResultsView(state: state, onPlay: (_, _) {})),
    );

    expect(find.textContaining('No results'), findsOneWidget);
  });
}
