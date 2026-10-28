import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Settings root (PRD S16). Flat grouped rows keep the list scannable; each
/// row pushes its dedicated sub-page.

/// Settings tab root.
final class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      body: MaxContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            12.w,
            pad,
            pad + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Text(
              AppLocalizations.of(context).settingsTitle,
              style: AppTypography.display.copyWith(
                fontSize: 30.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 4.w),
            Text(
              'Private by design · Offline first',
              style: AppTypography.caption.copyWith(fontSize: 14.sp),
            ),
            SizedBox(height: 34.w),
            const _SectionLabel('Personalise'),
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
            SizedBox(height: 26.w),
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
            SizedBox(height: 26.w),
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

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 6.w, bottom: 10.w),
      child: Text(label.toUpperCase(), style: AppTypography.overline),
    );
  }
}

final class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.glassBorder, width: 0.7),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.w),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 44.w,
                color: AppColors.glassBorder,
              ),
            children[i],
          ],
        ],
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
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 7.w),
      minLeadingWidth: 30.r,
      leading: SizedBox(
        width: 26.w,
        child: Icon(icon, size: 22.r, color: AppColors.textSecondary),
      ),
      title: Text(title, style: AppTypography.subtitle),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(fontSize: 13.5.sp),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20.r,
        color: AppColors.textTertiary,
      ),
      onTap: () => context.push(route),
    );
  }
}
