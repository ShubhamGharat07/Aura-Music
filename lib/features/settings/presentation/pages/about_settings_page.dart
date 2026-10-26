import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// About settings: version, privacy stance and resolved device tier.

/// About sub-page.
final class AboutSettingsPage extends HookWidget {
  /// Creates the about page.
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final l10n = AppLocalizations.of(context);
    final installed = useFuture(useMemoized(_version));
    final version = installed.data ?? '1.0.0+1';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
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
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.w),
                  Text(l10n.aboutVersion(version)),
                  SizedBox(height: 12.w),
                  Text(l10n.aboutPrivacy),
                ],
              ),
            ),
            SizedBox(height: 12.w),
            GlassSurface.fake(
              borderRadius: AppRadius.card,
              padding: EdgeInsets.symmetric(vertical: 4.w),
              child: ValueListenableBuilder<GlassTier>(
                valueListenable: getIt<DeviceTierService>().tier,
                builder: (context, tier, _) => ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: Text(l10n.glassTierTitle),
                  subtitle: Text(l10n.glassTierSubtitle),
                  trailing: Text(tier.name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> _version() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } on Object {
      return null;
    }
  }
}
