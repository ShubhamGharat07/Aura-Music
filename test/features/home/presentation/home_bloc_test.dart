import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/domain/repositories/home_repository.dart';
import 'package:aura_music/features/home/domain/usecases/get_artist_radio.dart';
import 'package:aura_music/features/home/domain/usecases/get_genre_tracks.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_genres.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_trending.dart';
import 'package:aura_music/features/home/domain/usecases/get_language_tracks.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_albums.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_releases.dart';
import 'package:aura_music/features/home/domain/usecases/get_popular_artists.dart';
import 'package:aura_music/features/home/domain/usecases/get_trending_albums.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockHomeRepository extends Mock implements HomeRepository {}

final class _FakeHistoryRepository implements PlayHistoryRepository {
  _FakeHistoryRepository([this.entries = const []]);

  List<HistoryEntry> entries;

  @override
  Stream<List<HistoryEntry>> watchRecent({int limit = 200}) =>
      Stream.value(entries.take(limit).toList(growable: false));

  @override
  Future<List<HistoryEntry>> recent({int limit = 200}) async =>
      entries.take(limit).toList(growable: false);

  @override
  Future<void> record(Track track) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  late _MockHomeRepository repository;

  const neon = Track(
    id: 'a',
    title: 'Neon',
    artist: 'Aurora',
    duration: Duration(minutes: 3),
  );
  const glass = Track(id: 'b', title: 'Glass', artist: 'Lumen');
  const tracks = [neon, glass];
  const chill = Genre(id: '16', name: 'Chill');
  const pop = Genre(id: '15', name: 'Pop');
  const marathi = CatalogLanguage(code: 'marathi', name: 'Marathi');
  const hindi = CatalogLanguage(code: 'hindi', name: 'Hindi');
  const mixtape = Album(
    id: '11',
    title: 'Mixtape',
    artist: 'Aurora',
    songCount: 4,
  );
  const arijit = Artist(id: '459320', name: 'Arijit Singh');

  setUpAll(() {
    registerFallbackValue(const Genre(id: 'fallback', name: 'Fallback'));
    registerFallbackValue(
      const CatalogLanguage(code: 'fallback', name: 'Fallback'),
    );
  });

  setUp(() {
    repository = _MockHomeRepository();
    when(
      () => repository.trending(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(tracks));
    when(
      () => repository.newReleases(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([glass]));
    when(
      () => repository.genres(),
    ).thenAnswer((_) async => const Right([chill, pop]));
    when(
      () => repository.byGenre(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([glass]));
    when(
      () => repository.byLanguage(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([glass]));
    when(
      () => repository.newAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([mixtape]));
    when(
      () => repository.trendingAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([mixtape]));
    when(
      () => repository.popularArtists(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right([arijit]));
  });

  HomeBloc makeBloc({List<HistoryEntry> history = const []}) {
    final bloc = HomeBloc(
      GetHomeTrending(repository),
      GetNewReleases(repository),
      GetArtistRadio(repository),
      GetHomeGenres(repository),
      GetGenreTracks(repository),
      GetLanguageTracks(repository),
      GetNewAlbums(repository),
      GetTrendingAlbums(repository),
      GetPopularArtists(repository),
      WatchHistory(_FakeHistoryRepository(history)),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  test('started loads the network sections and derives quick picks', () async {
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.trending.status, SectionStatus.ready);
    expect(bloc.state.newReleases.status, SectionStatus.ready);
    expect(bloc.state.quickPicks, hasLength(2));
    expect(bloc.state.seedArtist, isNull);
    expect(bloc.state.becauseYou.status, SectionStatus.empty);
    expect(bloc.state.offline, isFalse);
    expect(bloc.state.newAlbums.status, SectionStatus.ready);
    expect(bloc.state.newAlbums.albums.single.title, 'Mixtape');
    expect(bloc.state.trendingAlbums.status, SectionStatus.ready);
    verifyNever(() => repository.byArtist(any()));
  });

  test('an album feed failure only takes down its own grid', () async {
    when(
      () => repository.newAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.newAlbums.status, SectionStatus.error);
    expect(bloc.state.trendingAlbums.status, SectionStatus.ready);
    expect(bloc.state.trending.status, SectionStatus.ready);
  });

  test('an empty album feed hides the grid instead of erroring', () async {
    when(
      () => repository.trendingAlbums(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Album>[]));
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.trendingAlbums.status, SectionStatus.empty);
  });

  test('started loads the popular artist row', () async {
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.artists.status, SectionStatus.ready);
    expect(bloc.state.artists.artists.single.name, 'Arijit Singh');
  });

  test('an artist feed failure only takes down its own row', () async {
    when(
      () => repository.popularArtists(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.artists.status, SectionStatus.error);
    expect(bloc.state.artists.error, 'offline');
    expect(bloc.state.trendingAlbums.status, SectionStatus.ready);
    expect(bloc.state.newAlbums.status, SectionStatus.ready);
    expect(bloc.state.trending.status, SectionStatus.ready);
  });

  test('an empty artist row hides the section instead of erroring', () async {
    when(
      () => repository.popularArtists(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Artist>[]));
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.artists.status, SectionStatus.empty);
  });

  test(
    'offline marks the feed offline without blocking the other sections',
    () async {
      when(
        () => repository.trending(limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final bloc = makeBloc();

      bloc.add(const HomeStarted());
      await pumpEventQueue();

      expect(bloc.state.offline, isTrue);
      expect(bloc.state.trending.status, SectionStatus.error);
      expect(bloc.state.newReleases.status, SectionStatus.ready);
      verify(
        () => repository.newReleases(limit: any(named: 'limit')),
      ).called(1);
    },
  );

  test('a slow trending call does not block the other sections', () async {
    final gate = Completer<Either<Failure, List<Track>>>();
    when(
      () => repository.trending(limit: any(named: 'limit')),
    ).thenAnswer((_) => gate.future);
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.trending.status, SectionStatus.loading);
    expect(bloc.state.newReleases.status, SectionStatus.ready);

    gate.complete(const Right(tracks));
    await pumpEventQueue();

    expect(bloc.state.trending.status, SectionStatus.ready);
  });

  test('seeds the artist section from play history', () async {
    when(
      () => repository.byArtist(any()),
    ).thenAnswer((_) async => const Right([neon]));
    final bloc = makeBloc(
      history: [HistoryEntry(track: neon, playedAt: DateTime(2026, 1, 1))],
    );

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.seedArtist, 'Aurora');
    expect(bloc.state.becauseYou.status, SectionStatus.ready);
    verify(() => repository.byArtist('Aurora')).called(1);
  });

  test('continue listening de-duplicates and caps the history', () async {
    final history = [
      for (var i = 0; i < 12; i++)
        HistoryEntry(
          track: Track(id: 'id${i % 3}', title: 'T$i', artist: 'A'),
          playedAt: DateTime(2026, 1, 1, 0, i),
        ),
    ];
    final bloc = makeBloc(history: history);

    await pumpEventQueue();

    expect(bloc.state.continueListening.map((t) => t.id), [
      'id0',
      'id1',
      'id2',
    ]);
  });

  test('refresh reloads the sections and completes', () async {
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    await bloc.refresh();

    expect(bloc.state.trending.status, SectionStatus.ready);
    verify(() => repository.newReleases(limit: any(named: 'limit'))).called(2);
  });

  test('started loads the mood / genre chips', () async {
    final bloc = makeBloc();

    bloc.add(const HomeStarted());
    await pumpEventQueue();

    expect(bloc.state.genresStatus, SectionStatus.ready);
    expect(bloc.state.genres.map((genre) => genre.name), <String>[
      'Chill',
      'Pop',
    ]);
    expect(bloc.state.selectedGenre, isNull);
    expect(bloc.state.genreTracks.status, SectionStatus.empty);
  });

  test('selecting a genre swaps the feed to that genre', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();

    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();

    expect(bloc.state.selectedGenre, chill);
    expect(bloc.state.genreTracks.status, SectionStatus.ready);
    expect(bloc.state.genreTracks.tracks.single.title, 'Glass');
    verify(
      () => repository.byGenre(chill, limit: any(named: 'limit')),
    ).called(1);
  });

  test('the "All" chip clears the genre filter', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();

    bloc.add(const HomeGenreSelected(null));
    await pumpEventQueue();

    expect(bloc.state.selectedGenre, isNull);
    expect(bloc.state.genreTracks.status, SectionStatus.empty);
    expect(bloc.state.trending.status, SectionStatus.ready);
  });

  test('re-tapping the loaded genre chip does not refetch it', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();

    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();

    verify(
      () => repository.byGenre(chill, limit: any(named: 'limit')),
    ).called(1);
  });

  test('an empty genre result collapses the section', () async {
    when(
      () => repository.byGenre(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Right(<Track>[]));
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();

    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();

    expect(bloc.state.selectedGenre, chill);
    expect(bloc.state.genreTracks.status, SectionStatus.empty);
  });

  test(
    'a genre failure keeps the chip selected and reports the error',
    () async {
      when(
        () => repository.byGenre(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final bloc = makeBloc();
      bloc.add(const HomeStarted());
      await pumpEventQueue();

      bloc.add(const HomeGenreSelected(chill));
      await pumpEventQueue();

      expect(bloc.state.selectedGenre, chill);
      expect(bloc.state.genreTracks.status, SectionStatus.error);
    },
  );

  test('a stale genre result is dropped when the selection moved on', () async {
    final gate = Completer<Either<Failure, List<Track>>>();
    when(
      () => repository.byGenre(chill, limit: any(named: 'limit')),
    ).thenAnswer((_) => gate.future);
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();

    bloc.add(const HomeGenreSelected(chill));
    await pumpEventQueue();
    bloc.add(const HomeGenreSelected(null));
    await pumpEventQueue();

    gate.complete(const Right([glass]));
    await pumpEventQueue();

    expect(bloc.state.selectedGenre, isNull);
    expect(bloc.state.genreTracks.status, SectionStatus.empty);
  });

  test('opening a language loads its songs into the bottom section', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();

    bloc.add(const HomeLanguageSelected(marathi));
    await pumpEventQueue();

    expect(bloc.state.selectedLanguage, marathi);
    expect(bloc.state.languageTracks.status, SectionStatus.ready);
    expect(bloc.state.languageTracks.tracks.single.title, 'Glass');
    verify(
      () => repository.byLanguage(marathi, limit: any(named: 'limit')),
    ).called(1);
    expect(bloc.state.genresStatus, SectionStatus.ready);
  });

  test('re-tapping the open language collapses the section', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    bloc.add(const HomeLanguageSelected(marathi));
    await pumpEventQueue();

    bloc.add(const HomeLanguageSelected(marathi));
    await pumpEventQueue();

    expect(bloc.state.selectedLanguage, isNull);
    expect(bloc.state.languageTracks.status, SectionStatus.empty);
    verify(
      () => repository.byLanguage(marathi, limit: any(named: 'limit')),
    ).called(1);
  });

  test('switching language replaces the open section', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    bloc.add(const HomeLanguageSelected(marathi));
    await pumpEventQueue();

    bloc.add(const HomeLanguageSelected(hindi));
    await pumpEventQueue();

    expect(bloc.state.selectedLanguage, hindi);
    expect(bloc.state.languageTracks.status, SectionStatus.ready);
    verify(
      () => repository.byLanguage(hindi, limit: any(named: 'limit')),
    ).called(1);
  });

  test(
    'a language failure keeps the chip open and reports the error',
    () async {
      when(
        () => repository.byLanguage(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      final bloc = makeBloc();
      bloc.add(const HomeStarted());
      await pumpEventQueue();

      bloc.add(const HomeLanguageSelected(marathi));
      await pumpEventQueue();

      expect(bloc.state.selectedLanguage, marathi);
      expect(bloc.state.languageTracks.status, SectionStatus.error);
    },
  );

  test('refresh reloads an open language section', () async {
    final bloc = makeBloc();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    bloc.add(const HomeLanguageSelected(marathi));
    await pumpEventQueue();

    await bloc.refresh();

    expect(bloc.state.selectedLanguage, marathi);
    expect(bloc.state.languageTracks.status, SectionStatus.ready);
    verify(
      () => repository.byLanguage(marathi, limit: any(named: 'limit')),
    ).called(2);
  });
}
