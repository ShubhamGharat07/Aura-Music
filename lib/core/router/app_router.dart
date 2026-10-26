import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/animated_branch_stack.dart';
import 'package:aura_music/core/responsive/tiered_shell.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/features/album/presentation/pages/album_page.dart';
import 'package:aura_music/features/artist/presentation/pages/artist_page.dart';
import 'package:aura_music/features/downloads/presentation/pages/downloads_page.dart';
import 'package:aura_music/features/library/presentation/pages/history_page.dart';
import 'package:aura_music/features/library/presentation/pages/library_page.dart';
import 'package:aura_music/features/library/presentation/pages/liked_songs_page.dart';
import 'package:aura_music/features/library/presentation/pages/playlists_page.dart';
import 'package:aura_music/features/library/presentation/pages/user_playlist_page.dart';
import 'package:aura_music/features/player/presentation/pages/player_page.dart';
import 'package:aura_music/features/playlist/presentation/pages/playlist_page.dart';
import 'package:aura_music/features/search/presentation/pages/search_page.dart';
import 'package:aura_music/features/security/presentation/pages/privacy_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/about_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/audio_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:aura_music/features/settings/presentation/pages/updates_settings_page.dart';
import 'package:aura_music/features/home/presentation/bloc/albums_cubit.dart';
import 'package:aura_music/features/home/presentation/pages/albums_page.dart';
import 'package:aura_music/features/home/presentation/pages/home_page.dart';

/// App router (PRD 6.2). `StatefulShellRoute` keeps per-tab stacks and
/// scroll positions across rotation / resize (journey J7).

/// Builds the app [GoRouter].
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => TieredShell(navigationShell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            AnimatedBranchStack(
              currentIndex: shell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) =>
                    const RepaintBoundary(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) =>
                    const RepaintBoundary(child: SearchPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (context, state) =>
                    const RepaintBoundary(child: LibraryPage()),
                routes: [
                  GoRoute(
                    path: 'downloads',
                    builder: (context, state) => const DownloadsPage(),
                  ),
                  GoRoute(
                    path: 'liked',
                    builder: (context, state) => const LikedSongsPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const HistoryPage(),
                  ),
                  GoRoute(
                    path: 'playlists',
                    builder: (context, state) => const PlaylistsPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => UserPlaylistPage(
                          playlistId: state.pathParameters['id'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) =>
                    const RepaintBoundary(child: SettingsPage()),
                routes: [
                  GoRoute(
                    path: 'appearance',
                    builder: (context, state) => const AppearanceSettingsPage(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacySettingsPage(),
                  ),
                  GoRoute(
                    path: 'audio',
                    builder: (context, state) => const AudioSettingsPage(),
                  ),
                  GoRoute(
                    path: 'storage',
                    builder: (context, state) => const StorageSettingsPage(),
                  ),
                  GoRoute(
                    path: 'updates',
                    builder: (context, state) => const UpdatesSettingsPage(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.player,
        builder: (context, state) => const PlayerPage(),
      ),
      GoRoute(
        path: '${AppRoutes.album}/:id',
        builder: (context, state) =>
            AlbumPage(albumId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.artist}/:id',
        builder: (context, state) =>
            ArtistPage(artistId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.playlist}/:id',
        builder: (context, state) =>
            PlaylistPage(playlistId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.albums}/:kind',
        builder: (context, state) => AlbumsPage(
          kind: AlbumsKind.fromSlug(state.pathParameters['kind'] ?? ''),
        ),
      ),
    ],
  );
}
