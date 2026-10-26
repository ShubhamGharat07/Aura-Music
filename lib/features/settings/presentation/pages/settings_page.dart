import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Settings root (PRD S16). Grouped glass cards keep the list scannable; each
/// row pushes its dedicated sub-page.

/// Settings tab root.
final class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).settingsTitle)),
      body: MaxContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            pad,
            pad,
            pad + MediaQuery.paddingOf(context).bottom,
          ),
          children: const [
            _BrandCard(),
            SizedBox(height: 20),
            _SectionLabel('Personalise'),
            _Group(
              children: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Glass effect, dynamic colour, AMOLED',
                  route: AppRoutes.settingsAppearance,
                ),
                _SettingsTile(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Audio & EQ',
                  subtitle: 'Playback speed, skip silence, equalizer',
                  route: AppRoutes.settingsAudio,
                ),
                _SettingsTile(
                  icon: Icons.system_update_alt_rounded,
                  title: 'Updates',
                  subtitle: 'Installed version and update checks',
                  route: AppRoutes.settingsUpdates,
                ),
              ],
            ),
            SizedBox(height: 20),
            _SectionLabel('Data & privacy'),
            _Group(
              children: [
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: 'Storage & downloads',
                  subtitle: 'Offline tracks and space used',
                  route: AppRoutes.settingsStorage,
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & security',
                  subtitle: 'App lock, screenshots, history, data',
                  route: AppRoutes.settingsPrivacy,
                ),
              ],
            ),
            SizedBox(height: 20),
            _SectionLabel('About'),
            _Group(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Aura',
                  subtitle: 'Version, privacy and credits',
                  route: AppRoutes.settingsAbout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.22), AppColors.glassFill],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 26.r,
                  color: accent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).appTitle,
                      style: AppTypography.title,
                    ),
                    SizedBox(height: 2.w),
                    Text(
                      'Private by design · Offline first',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.w),
      child: Text(label.toUpperCase(), style: AppTypography.overline),
    );
  }
}

final class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.symmetric(vertical: 4.w),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 60.w,
                  endIndent: 14.w,
                  color: AppColors.glassBorder,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

final class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.w),
      minLeadingWidth: 38.r,
      leading: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, size: 20.r, color: accent),
      ),
      title: Text(title, style: AppTypography.subtitle),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: () => context.push(route),
    );
  }
}
