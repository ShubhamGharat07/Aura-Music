import 'package:aura_music/features/settings/domain/entities/app_settings.dart';

/// Settings repository contract (domain). Impl wraps SharedPreferences
/// and is never read directly from widgets (PRD 4.1).

/// Persists [AppSettings].
abstract class SettingsRepository {
  /// Loads settings (defaults when missing).
  Future<AppSettings> load();

  /// Saves settings.
  Future<void> save(AppSettings settings);
}
