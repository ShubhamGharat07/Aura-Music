import 'package:get_it/get_it.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/home/data/repositories/home_repository_impl.dart';
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
import 'package:aura_music/features/home/presentation/bloc/albums_cubit.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';

/// Home feature registrations (PRD S03), kept out of [configureDependencies]
/// so the locator file stays small.

/// Registers the home repository, use cases and bloc.
void registerHomeDependencies(GetIt getIt) {
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      getIt<JiosaavnRemoteDataSource>(),
      persistentCache: getIt<PersistentCache>(),
    ),
  );
  getIt.registerLazySingleton<GetHomeTrending>(
    () => GetHomeTrending(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetNewReleases>(
    () => GetNewReleases(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetArtistRadio>(
    () => GetArtistRadio(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetHomeGenres>(
    () => GetHomeGenres(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetGenreTracks>(
    () => GetGenreTracks(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetLanguageTracks>(
    () => GetLanguageTracks(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetNewAlbums>(
    () => GetNewAlbums(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetTrendingAlbums>(
    () => GetTrendingAlbums(getIt<HomeRepository>()),
  );
  getIt.registerLazySingleton<GetPopularArtists>(
    () => GetPopularArtists(getIt<HomeRepository>()),
  );
  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      getIt<GetHomeTrending>(),
      getIt<GetNewReleases>(),
      getIt<GetArtistRadio>(),
      getIt<GetHomeGenres>(),
      getIt<GetGenreTracks>(),
      getIt<GetLanguageTracks>(),
      getIt<GetNewAlbums>(),
      getIt<GetTrendingAlbums>(),
      getIt<GetPopularArtists>(),
      getIt<WatchHistory>(),
    ),
  );
  getIt.registerFactory<AlbumsCubit>(
    () => AlbumsCubit(getIt<GetNewAlbums>(), getIt<GetTrendingAlbums>()),
  );
}
