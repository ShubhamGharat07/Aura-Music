import 'package:aura_music/features/security/domain/entities/security_settings.dart';

/// Security settings contract (domain). The impl wraps SharedPreferences and
/// is never read directly from widgets (PRD 4.1).

/// Persists [SecuritySettings].
abstract interface class SecurityRepository {
  /// Loads settings (defaults when missing).
  Future<SecuritySettings> load();

  /// Saves settings.
  Future<void> save(SecuritySettings settings);
}
