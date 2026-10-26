import 'package:get_it/get_it.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/cached_tracks_dao.dart';
import 'package:aura_music/database/daos/search_history_dao.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/search/data/repositories/search_history_repository_impl.dart';
import 'package:aura_music/features/search/data/repositories/search_repository_impl.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';
import 'package:aura_music/features/search/domain/usecases/clear_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/get_browse_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/get_recent_searches.dart';
import 'package:aura_music/features/search/domain/usecases/get_suggestions.dart';
import 'package:aura_music/features/search/domain/usecases/remove_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/save_recent_search.dart';
import 'package:aura_music/features/search/domain/usecases/search_catalog.dart';
import 'package:aura_music/features/search/presentation/bloc/search_bloc.dart';

/// Search registrations (PRD S05), kept out of [configureDependencies] so the
/// locator file stays small.

/// Registers the search repository, offline cache, use cases and bloc.
void registerSearchDependencies(GetIt getIt) {
  getIt.registerLazySingleton<CachedTracksDao>(
    () => CachedTracksDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      getIt<JiosaavnRemoteDataSource>(),
      cache: getIt<CachedTracksDao>(),
    ),
  );
  getIt.registerLazySingleton<SearchHistoryDao>(
    () => SearchHistoryDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<SearchHistoryRepository>(
    () => DriftSearchHistoryRepository(getIt<SearchHistoryDao>()),
  );
  getIt.registerLazySingleton<SearchCatalog>(
    () => SearchCatalog(getIt<SearchRepository>()),
  );
  getIt.registerLazySingleton<GetSuggestions>(
    () => GetSuggestions(getIt<SearchRepository>()),
  );
  getIt.registerLazySingleton<GetBrowseSuggestions>(
    () => GetBrowseSuggestions(getIt<SearchRepository>()),
  );
  getIt.registerLazySingleton<GetRecentSearches>(
    () => GetRecentSearches(getIt<SearchHistoryRepository>()),
  );
  getIt.registerLazySingleton<SaveRecentSearch>(
    () => SaveRecentSearch(getIt<SearchHistoryRepository>()),
  );
  getIt.registerLazySingleton<ClearRecentSearches>(
    () => ClearRecentSearches(getIt<SearchHistoryRepository>()),
  );
  getIt.registerLazySingleton<RemoveRecentSearch>(
    () => RemoveRecentSearch(getIt<SearchHistoryRepository>()),
  );
  getIt.registerFactory<SearchBloc>(
    () => SearchBloc(
      getIt<SearchCatalog>(),
      getIt<GetSuggestions>(),
      getIt<GetBrowseSuggestions>(),
      getIt<GetRecentSearches>(),
      getIt<SaveRecentSearch>(),
      getIt<ClearRecentSearches>(),
      getIt<RemoveRecentSearch>(),
    ),
  );
}
