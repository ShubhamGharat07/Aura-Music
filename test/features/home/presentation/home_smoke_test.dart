import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/downloads/domain/usecases/download_track.dart';
import 'package:aura_music/features/downloads/domain/usecases/pause_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/remove_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/resume_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/retry_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/watch_downloads.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
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
import 'package:aura_music/features/home/presentation/widgets/home_compact_view.dart';
import 'package:aura_music/features/home/presentation/widgets/home_wide_view.dart';
import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/library/domain/usecases/add_track_to_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/create_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';
import 'package:aura_music/features/library/domain/usecases/watch_playlists.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/window_sizes.dart';

final List<Track> _tracks = [
  for (var i = 0; i < 6; i++)
    Track(id: 't$i', title: 'Track $i', artist: 'Artist $i', album: 'Album $i'),
];

final List<Album> _albums = [
  for (var i = 0; i < 5; i++)
    Album(id: 'al$i', title: 'Album $i', artist: 'Artist $i', songCount: i + 2),
];

final List<Artist> _artists = [
  for (var i = 0; i < 8; i++) Artist(id: 'ar$i', name: 'Artist $i'),
];

final class _FakeHomeRepository implements HomeRepository {
  @override
  Future<Either<Failure, List<Track>>> trending({int limit = 20}) async =>
      Right(_tracks);

  @override
  Future<Either<Failure, List<Track>>> newReleases({int limit = 20}) async =>
      Right(_tracks);

  @override
  Future<Either<Failure, List<Track>>> byArtist(
    String artist, {
    int limit = 20,
  }) async => Right(_tracks);

  @override
  Future<Either<Failure, List<Genre>>> genres() async =>
      const Right(<Genre>[Genre(id: '16', name: 'Chill')]);

  @override
  Future<Either<Failure, List<Track>>> byGenre(
    Genre genre, {
    int limit = 20,
  }) async => Right(_tracks);

  @override
  Future<Either<Failure, List<Track>>> byLanguage(
    CatalogLanguage language, {
    int limit = 20,
  }) async => Right(_tracks);

  @override
  Future<Either<Failure, List<Album>>> newAlbums({int limit = 30}) async =>
      Right(_albums);

  @override
  Future<Either<Failure, List<Album>>> trendingAlbums({int limit = 24}) async =>
      Right(_albums);

  @override
  Future<Either<Failure, List<Artist>>> popularArtists({
    int limit = 20,
  }) async => Right(_artists);
}

final class _FakeHistoryRepository implements PlayHistoryRepository {
  @override
  Stream<List<HistoryEntry>> watchRecent({int limit = 200}) =>
      Stream.value(const []);

  @override
  Future<List<HistoryEntry>> recent({int limit = 200}) async => const [];

  @override
  Future<void> record(Track track) async {}

  @override
  Future<void> clear() async {}
}

final class _FakePlaylistsRepository implements UserPlaylistRepository {
  @override
  Stream<List<UserPlaylist>> watchAll() => Stream.value(const []);

  @override
  Future<List<UserPlaylist>> all() async => const [];

  @override
  Future<UserPlaylistDetail?> detail(String id) async => null;

  @override
  Future<String> create(String name, {String? description}) async => 'p1';

  @override
  Future<void> rename(String id, String name) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> addTrack(String playlistId, Track track) async {}

  @override
  Future<void> removeTrack(String playlistId, String trackId) async {}
}

final class _FakeDownloadsRepository implements DownloadsRepository {
  @override
  Stream<List<Download>> watchAll() => Stream.value(const []);

  @override
  Future<List<Download>> all() async => const [];

  @override
  Future<Either<Failure, Unit>> enqueue(Track track) async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> remove(String trackId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> pause(String trackId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> resume(String trackId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> retry(String trackId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, String?>> localFileFor(String trackId) async =>
      const Right(null);
}

void main() {
  for (final size in kWindowSizes) {
    final sizeClass = WindowSizeClass.ofWidth(size.width);
    final view = switch (sizeClass) {
      WindowSizeClass.compact => const HomeCompactView(),
      WindowSizeClass.medium ||
      WindowSizeClass.expanded => const HomeWideView(),
      WindowSizeClass.large => const HomeWideView(showRecentlyPlayed: true),
    };
    final design = switch (sizeClass) {
      WindowSizeClass.compact => const Size(393, 852),
      WindowSizeClass.medium => const Size(744, 1133),
      WindowSizeClass.expanded ||
      WindowSizeClass.large => const Size(1194, 834),
    };
    testWidgets(
      'home has no overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await _pumpHome(tester, size, design, view);
      },
    );
  }
}

Future<void> _pumpHome(
  WidgetTester tester,
  Size size,
  Size design,
  Widget view,
) async {
  {
    final home = _FakeHomeRepository();
    final history = _FakeHistoryRepository();
    final playlists = _FakePlaylistsRepository();
    final downloads = _FakeDownloadsRepository();

    final homeBloc = HomeBloc(
      GetHomeTrending(home),
      GetNewReleases(home),
      GetArtistRadio(home),
      GetHomeGenres(home),
      GetGenreTracks(home),
      GetLanguageTracks(home),
      GetNewAlbums(home),
      GetTrendingAlbums(home),
      GetPopularArtists(home),
      WatchHistory(history),
    )..add(const HomeStarted());

    final playlistsCubit = PlaylistsCubit(
      WatchPlaylists(playlists),
      CreatePlaylist(playlists),
      AddTrackToPlaylist(playlists),
    )..load();

    final downloadsCubit = DownloadsCubit(
      WatchDownloads(downloads),
      DownloadTrack(downloads),
      RemoveDownload(downloads),
      PauseDownload(downloads),
      ResumeDownload(downloads),
      RetryDownload(downloads),
    );

    addTearDown(() async {
      await homeBloc.close();
      await playlistsCubit.close();
      await downloadsCubit.close();
    });

    await pumpApp(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<PlaylistsCubit>.value(value: playlistsCubit),
          BlocProvider<DownloadsCubit>.value(value: downloadsCubit),
        ],
        child: view,
      ),
      size: size,
      designSize: design,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Track 0'), findsWidgets);
  }
}
