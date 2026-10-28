// Route paths (PRD 6.2). Navigation uses `go_router` only;
// `Navigator.of(context)` is banned outside `core/router`.

/// App route paths.
abstract final class AppRoutes {
  /// Tab roots.
  static const String home = '/home';

  /// Tab roots.
  static const String search = '/search';

  /// Tab roots.
  static const String library = '/library';

  /// Tab roots.
  static const String settings = '/settings';

  /// Full-screen now playing (compact / medium sheets use this route).
  static const String player = '/player';

  /// Album detail (`/album/:id`).
  static const String album = '/album';

  /// Artist detail (`/artist/:id`).
  static const String artist = '/artist';

  /// Playlist detail (`/playlist/:id`).
  static const String playlist = '/playlist';

  /// Album grid browse (`/albums/:kind`, "See all" from home).
  static const String albums = '/albums';

  /// Full Top picks chart (`See all` from Home).
  static const String topPicks = '/top-picks';

  /// Offline downloads (nested under the Library tab).
  static const String downloads = '/library/downloads';

  /// Liked songs (nested under the Library tab).
  static const String liked = '/library/liked';

  /// Play history (nested under the Library tab).
  static const String history = '/library/history';

  /// User playlists (nested under the Library tab).
  static const String playlists = '/library/playlists';

  /// Appearance settings sub-page.
  static const String settingsAppearance = '/settings/appearance';

  /// Privacy & security settings sub-page.
  static const String settingsPrivacy = '/settings/privacy';

  /// Storage & downloads settings sub-page.
  static const String settingsStorage = '/settings/storage';

  /// Audio & EQ settings sub-page (`/settings/audio`).
  static const String settingsAudio = '/settings/audio';

  /// Updates settings sub-page (`/settings/updates`).
  static const String settingsUpdates = '/settings/updates';

  /// About settings sub-page.
  static const String settingsAbout = '/settings/about';
}
