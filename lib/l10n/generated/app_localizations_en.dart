// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aura Music';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutPrivacy =>
      'A premium, privacy-first music player. Your library and playback history stay on this device - no account, no telemetry.';

  @override
  String get glassTierTitle => 'Glass tier';

  @override
  String get glassTierSubtitle => 'Auto-detected from this device';

  @override
  String get audioTitle => 'Audio & EQ';

  @override
  String get updatesTitle => 'Updates';

  @override
  String get settingsTitle => 'Settings';
}
