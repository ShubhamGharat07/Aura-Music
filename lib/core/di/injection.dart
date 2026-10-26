import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/data/persistent_cache.dart';
import 'package:aura_music/core/di/modules/home_module.dart';
import 'package:aura_music/core/di/modules/party_module.dart';
import 'package:aura_music/core/di/modules/lyrics_module.dart';
import 'package:aura_music/core/di/modules/search_module.dart';
import 'package:aura_music/core/di/modules/security_module.dart';
import 'package:aura_music/core/network/dio_client.dart';
import 'package:aura_music/core/services/app_notification_service.dart';
import 'package:aura_music/core/services/audio_session_service.dart';
import 'package:aura_music/core/services/connectivity_cubit.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/services/dynamic_accent_service.dart';
import 'package:aura_music/core/services/permission_service.dart';
import 'package:aura_music/core/services/playback/just_audio_playback_controller.dart';
import 'package:aura_music/core/services/playback/media_session_service.dart';
import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/core/services/secure_key_service.dart';
import 'package:aura_music/core/services/update_service.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/api_cache_dao.dart';
import 'package:aura_music/database/database_opener.dart';
import 'package:aura_music/database/daos/downloads_dao.dart';
import 'package:aura_music/database/daos/history_dao.dart';
import 'package:aura_music/database/daos/liked_songs_dao.dart';
import 'package:aura_music/database/daos/user_playlists_dao.dart';
import 'package:aura_music/features/album/data/repositories/album_repository_impl.dart';
import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/album/domain/usecases/get_album.dart';
import 'package:aura_music/features/album/presentation/bloc/album_cubit.dart';
import 'package:aura_music/features/artist/data/repositories/artist_repository_impl.dart';
import 'package:aura_music/features/artist/domain/repositories/artist_repository.dart';
import 'package:aura_music/features/artist/domain/usecases/get_artist.dart';
import 'package:aura_music/features/artist/presentation/bloc/artist_cubit.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:aura_music/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:aura_music/features/catalog/domain/usecases/get_trending_tracks.dart';
import 'package:aura_music/features/downloads/data/datasources/download_engine.dart';
import 'package:aura_music/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:aura_music/features/downloads/domain/repositories/downloads_repository.dart';
import 'package:aura_music/features/downloads/domain/usecases/download_track.dart';
import 'package:aura_music/features/downloads/domain/usecases/get_downloaded_file.dart';
import 'package:aura_music/features/downloads/domain/usecases/pause_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/remove_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/resume_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/retry_download.dart';
import 'package:aura_music/features/downloads/domain/usecases/watch_downloads.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/library/data/repositories/liked_songs_repository_impl.dart';
import 'package:aura_music/features/library/data/repositories/play_history_repository_impl.dart';
import 'package:aura_music/features/library/data/repositories/user_playlist_repository_impl.dart';
import 'package:aura_music/features/library/domain/repositories/liked_songs_repository.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/library/domain/repositories/user_playlist_repository.dart';
import 'package:aura_music/features/library/domain/usecases/add_track_to_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/clear_history.dart';
import 'package:aura_music/features/library/domain/usecases/create_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/delete_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/get_user_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/record_play.dart';
import 'package:aura_music/features/library/domain/usecases/remove_liked_track.dart';
import 'package:aura_music/features/library/domain/usecases/remove_track_from_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/rename_playlist.dart';
import 'package:aura_music/features/library/domain/usecases/toggle_like.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';
import 'package:aura_music/features/library/domain/usecases/watch_liked_tracks.dart';
import 'package:aura_music/features/library/domain/usecases/watch_playlists.dart';
import 'package:aura_music/features/library/presentation/bloc/history_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/library_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/user_playlist_cubit.dart';
import 'package:aura_music/features/lyrics/data/datasources/unison_remote_data_source.dart';
import 'package:aura_music/features/player/data/repositories/prefs_playback_session_repository.dart';
import 'package:aura_music/features/player/data/services/sleep_timer_service.dart';
import 'package:aura_music/features/player/domain/repositories/playback_session_repository.dart';
import 'package:aura_music/features/player/domain/usecases/restore_playback_session.dart';
import 'package:aura_music/features/player/domain/usecases/save_playback_session.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:aura_music/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:aura_music/features/playlist/domain/usecases/get_playlist.dart';
import 'package:aura_music/features/playlist/presentation/bloc/playlist_cubit.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';
import 'package:aura_music/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:aura_music/features/settings/domain/repositories/settings_repository.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:aura_music/features/stream_resolver/data/datasources/jiosaavn_stream_source.dart';
import 'package:aura_music/features/stream_resolver/data/repositories/stream_repository_impl.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_repository.dart';
import 'package:aura_music/features/stream_resolver/domain/repositories/stream_source.dart';
import 'package:aura_music/features/stream_resolver/domain/usecases/resolve_stream.dart';

/// Service locator. Manual registration for Phase 0 (no codegen yet);
/// `injectable_generator` + drift codegen land with Phase 1 streaming.
///
/// BLoCs depend on UseCases only; impls are injected here.

/// Global locator.
final GetIt getIt = GetIt.instance;

/// Registers all dependencies. Called once from [bootstrap].
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<SecureKeyService>(() => SecureKeyService());
  getIt.registerLazySingleton<DeviceTierService>(() => DeviceTierService());
  getIt.registerLazySingleton<DynamicAccentService>(
    () => DynamicAccentService(),
  );
  getIt.registerLazySingleton<AudioSessionService>(
    () => const AudioSessionService(),
  );
  getIt.registerLazySingleton<PermissionService>(
    () => const PermissionService(),
  );
  getIt.registerLazySingleton<UpdateService>(() => UpdateService(Dio()));
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<Dio>(
    () => createDioClient(baseUrl: 'https://lrclib.net'),
  );
  getIt.registerLazySingleton<UnisonRemoteDataSource>(
    () => UnisonRemoteDataSource(
      createDioClient(baseUrl: 'https://unison.boidu.dev'),
    ),
  );
  getIt.registerLazySingleton<JiosaavnRemoteDataSource>(
    () => JiosaavnRemoteDataSource(
      createDioClient(baseUrl: 'https://www.jiosaavn.com'),
    ),
  );
  getIt.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(getIt<JiosaavnRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetTrendingTracks>(
    () => GetTrendingTracks(getIt<CatalogRepository>()),
  );
  registerHomeDependencies(getIt);
  registerSearchDependencies(getIt);
  getIt.registerLazySingleton<AlbumRepository>(
    () => AlbumRepositoryImpl(
      getIt<JiosaavnRemoteDataSource>(),
      cache: getIt<PersistentCache>(),
    ),
  );
  getIt.registerLazySingleton<GetAlbum>(
    () => GetAlbum(getIt<AlbumRepository>()),
  );
  getIt.registerFactory<AlbumCubit>(() => AlbumCubit(getIt<GetAlbum>()));
  getIt.registerLazySingleton<ArtistRepository>(
    () => ArtistRepositoryImpl(
      getIt<JiosaavnRemoteDataSource>(),
      cache: getIt<PersistentCache>(),
    ),
  );
  getIt.registerLazySingleton<GetArtist>(
    () => GetArtist(getIt<ArtistRepository>()),
  );
  getIt.registerFactory<ArtistCubit>(() => ArtistCubit(getIt<GetArtist>()));
  getIt.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(
      getIt<JiosaavnRemoteDataSource>(),
      cache: getIt<PersistentCache>(),
    ),
  );
  getIt.registerLazySingleton<GetPlaylist>(
    () => GetPlaylist(getIt<PlaylistRepository>()),
  );
  getIt.registerFactory<PlaylistCubit>(
    () => PlaylistCubit(getIt<GetPlaylist>()),
  );
  getIt.registerLazySingleton<LikedSongsDao>(
    () => LikedSongsDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<LikedSongsRepository>(
    () => DriftLikedSongsRepository(getIt<LikedSongsDao>()),
  );
  getIt.registerLazySingleton<WatchLikedTracks>(
    () => WatchLikedTracks(getIt<LikedSongsRepository>()),
  );
  getIt.registerLazySingleton<ToggleLike>(
    () => ToggleLike(getIt<LikedSongsRepository>()),
  );
  getIt.registerLazySingleton<RemoveLikedTrack>(
    () => RemoveLikedTrack(getIt<LikedSongsRepository>()),
  );
  getIt.registerFactory<LikedTracksCubit>(
    () => LikedTracksCubit(
      getIt<WatchLikedTracks>(),
      getIt<ToggleLike>(),
      getIt<RemoveLikedTrack>(),
    ),
  );
  getIt.registerFactory<LibraryCubit>(
    () => LibraryCubit(getIt<GetTrendingTracks>()),
  );
  getIt.registerLazySingleton<HistoryDao>(
    () => HistoryDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<PlayHistoryRepository>(
    () => DriftPlayHistoryRepository(getIt<HistoryDao>()),
  );
  getIt.registerLazySingleton<WatchHistory>(
    () => WatchHistory(getIt<PlayHistoryRepository>()),
  );
  getIt.registerLazySingleton<RecordPlay>(
    () => RecordPlay(getIt<PlayHistoryRepository>()),
  );
  getIt.registerLazySingleton<ClearHistory>(
    () => ClearHistory(getIt<PlayHistoryRepository>()),
  );
  getIt.registerFactory<HistoryCubit>(
    () => HistoryCubit(getIt<WatchHistory>(), getIt<ClearHistory>()),
  );
  getIt.registerLazySingleton<UserPlaylistsDao>(
    () => UserPlaylistsDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<UserPlaylistRepository>(
    () => DriftUserPlaylistRepository(getIt<UserPlaylistsDao>()),
  );
  getIt.registerLazySingleton<WatchPlaylists>(
    () => WatchPlaylists(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<GetUserPlaylist>(
    () => GetUserPlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<CreatePlaylist>(
    () => CreatePlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<RenamePlaylist>(
    () => RenamePlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<DeletePlaylist>(
    () => DeletePlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<AddTrackToPlaylist>(
    () => AddTrackToPlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerLazySingleton<RemoveTrackFromPlaylist>(
    () => RemoveTrackFromPlaylist(getIt<UserPlaylistRepository>()),
  );
  getIt.registerFactory<PlaylistsCubit>(
    () => PlaylistsCubit(
      getIt<WatchPlaylists>(),
      getIt<CreatePlaylist>(),
      getIt<AddTrackToPlaylist>(),
    ),
  );
  getIt.registerFactory<UserPlaylistCubit>(
    () => UserPlaylistCubit(
      getIt<GetUserPlaylist>(),
      getIt<RenamePlaylist>(),
      getIt<DeletePlaylist>(),
      getIt<RemoveTrackFromPlaylist>(),
    ),
  );
  registerLyricsDependencies(getIt);
  getIt.registerLazySingleton<AppDatabase>(
    () => AppDatabase(
      openAuraDatabase(keyProvider: getIt<SecureKeyService>().getOrCreateKey),
    ),
  );
  getIt.registerLazySingleton<ApiCacheDao>(
    () => ApiCacheDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<PersistentCache>(
    () => PersistentCache(getIt<ApiCacheDao>()),
  );
  registerSecurityDependencies(getIt);
  getIt.registerLazySingleton<DownloadsDao>(
    () => DownloadsDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<DownloadEngine>(
    () => DioDownloadEngine(createDownloadDio()),
  );
  getIt.registerLazySingleton<DownloadsRepository>(
    () =>
        DownloadsRepositoryImpl(getIt<DownloadsDao>(), getIt<DownloadEngine>()),
  );
  getIt.registerLazySingleton<WatchDownloads>(
    () => WatchDownloads(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<DownloadTrack>(
    () => DownloadTrack(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<RemoveDownload>(
    () => RemoveDownload(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<PauseDownload>(
    () => PauseDownload(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<ResumeDownload>(
    () => ResumeDownload(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<RetryDownload>(
    () => RetryDownload(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<GetDownloadedFile>(
    () => GetDownloadedFile(getIt<DownloadsRepository>()),
  );
  getIt.registerLazySingleton<DownloadsCubit>(
    () => DownloadsCubit(
      getIt<WatchDownloads>(),
      getIt<DownloadTrack>(),
      getIt<RemoveDownload>(),
      getIt<PauseDownload>(),
      getIt<ResumeDownload>(),
      getIt<RetryDownload>(),
      resolveStream: getIt<ResolveStream>(),
    ),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => PrefsSettingsRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<SettingsCubit>(
    () =>
        SettingsCubit(getIt<SettingsRepository>(), getIt<DeviceTierService>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  getIt.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  getIt.registerLazySingleton<AppNotificationService>(
    () => AppNotificationService(FlutterLocalNotificationsPlugin()),
  );
  getIt.registerLazySingleton<PlaybackController>(
    () => JustAudioPlaybackController(
      localFileResolver: (trackId) async =>
          (await getIt<GetDownloadedFile>()(trackId)).getOrElse((_) => null),
    ),
  );
  getIt.registerLazySingleton<SleepTimerService>(
    () => SleepTimerService(getIt<PlaybackController>()),
  );
  getIt.registerLazySingleton<List<StreamSource>>(
    () => <StreamSource>[
      JiosaavnStreamSource(getIt<JiosaavnRemoteDataSource>()),
    ],
  );
  getIt.registerLazySingleton<StreamRepository>(
    () => StreamRepositoryImpl(getIt<List<StreamSource>>()),
  );
  getIt.registerLazySingleton<ResolveStream>(
    () => ResolveStream(getIt<StreamRepository>()),
  );
  getIt.registerLazySingleton<PlaybackSessionRepository>(
    () => PrefsPlaybackSessionRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<RestorePlaybackSession>(
    () => RestorePlaybackSession(getIt<PlaybackSessionRepository>()),
  );
  getIt.registerLazySingleton<SavePlaybackSession>(
    () => SavePlaybackSession(getIt<PlaybackSessionRepository>()),
  );
  getIt.registerLazySingleton<PlayerBloc>(
    () => PlayerBloc(
      getIt<PlaybackController>(),
      getIt<ResolveStream>(),
      watchLiked: getIt<WatchLikedTracks>(),
      toggleLike: getIt<ToggleLike>(),
      recordPlay: getIt<RecordPlay>(),
      restoreSession: getIt<RestorePlaybackSession>(),
      saveSession: getIt<SavePlaybackSession>(),
      shouldRecordPlay: () =>
          !getIt<SecurityCubit>().state.settings.pauseHistory,
      isDownloaded: (trackId) async =>
          (await getIt<GetDownloadedFile>()(trackId)).getOrElse((_) => null) !=
          null,
    ),
  );
  getIt.registerLazySingleton<MediaSessionService>(
    () => MediaSessionService(
      player: getIt<PlayerBloc>(),
      controller: getIt<PlaybackController>(),
    ),
  );
  registerPartyDependencies(getIt);
}
