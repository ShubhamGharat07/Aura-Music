import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/update_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Updates settings (PRD S21 / F15): shows the real installed version and
/// checks the release manifest configured for this build.

/// Updates sub-page.
final class UpdatesSettingsPage extends HookWidget {
  /// Creates the updates page.
  const UpdatesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final info = useFuture(useMemoized(_current));
    final checking = useState(false);
    final latest = useState<UpdateInfo?>(null);
    final failed = useState(false);

    Future<void> check() async {
      checking.value = true;
      failed.value = false;
      try {
        final result = await _service()?.check();
        latest.value = result;
        failed.value = result == null;
      } on Object {
        latest.value = null;
        failed.value = true;
      } finally {
        checking.value = false;
      }
    }

    final version = info.hasData
        ? 'Version ${info.data!.version} (${info.data!.buildNumber})'
        : 'Reading version...';

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).updatesTitle)),
      body: MaxContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            pad,
            pad,
            pad + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            GlassSurface.fake(
              borderRadius: AppRadius.card,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aura Music', style: AppTypography.title),
                  SizedBox(height: 4.w),
                  Text(version),
                  SizedBox(height: 16.w),
                  FilledButton.icon(
                    onPressed: checking.value ? null : check,
                    icon: checking.value
                        ? SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      checking.value ? 'Checking...' : 'Check for updates',
                    ),
                  ),
                  SizedBox(height: 12.w),
                  _status(
                    currentVersion: info.hasData ? info.data!.version : null,
                    failedToCheck: failed.value,
                    update: latest.value,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status({
    required String? currentVersion,
    required bool failedToCheck,
    required UpdateInfo? update,
  }) {
    if (failedToCheck) {
      return const Text(
        'No update channel is configured for this build, or the server could '
        'not be reached.',
      );
    }
    if (update == null) {
      return const Text(
        'Updates are published through the release manifest; nothing has been '
        'checked yet.',
      );
    }
    if (currentVersion != null && update.version == currentVersion) {
      return const Text('You are on the latest version.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Version ${update.version} is available.'),
        if (update.notes != null && update.notes!.isNotEmpty) ...[
          SizedBox(height: 8.w),
          Text(update.notes!),
        ],
        if (update.downloadUrl != null) ...[
          SizedBox(height: 8.w),
          SelectableText(update.downloadUrl!),
        ],
      ],
    );
  }

  static Future<PackageInfo?> _current() async {
    try {
      return await PackageInfo.fromPlatform();
    } on Object {
      return null;
    }
  }

  static UpdateService? _service() {
    try {
      return getIt<UpdateService>();
    } on Object {
      return null;
    }
  }
}
