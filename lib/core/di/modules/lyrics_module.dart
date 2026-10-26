import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:aura_music/features/lyrics/data/datasources/lrclib_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/datasources/unison_remote_data_source.dart';
import 'package:aura_music/features/lyrics/data/repositories/lyrics_repository_impl.dart';
import 'package:aura_music/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:aura_music/features/lyrics/domain/usecases/get_lyrics.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';

/// Lyrics registrations (PRD S13), kept out of [configureDependencies] so the
/// locator file stays small.

/// Registers lyrics data sources, repository, use case and cubit.
void registerLyricsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<LrclibRemoteDataSource>(
    () => LrclibRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LyricsRepository>(
    () => LyricsRepositoryImpl(
      getIt<LrclibRemoteDataSource>(),
      getIt<UnisonRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetLyrics>(
    () => GetLyrics(getIt<LyricsRepository>()),
  );
  getIt.registerFactory<LyricsCubit>(() => LyricsCubit(getIt<GetLyrics>()));
}
