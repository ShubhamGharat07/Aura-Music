import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/app_dialog.dart';
import 'package:aura_music/core/services/data_reset_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/search/domain/usecases/clear_recent_searches.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';

/// Privacy & security settings (PRD S20): app lock, screenshot blocking,
/// history pause and the local-data controls.

/// Privacy & security sub-page.
final class PrivacySettingsPage extends StatelessWidget {
  /// Creates the privacy page.
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & security')),
      body: MaxContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            pad,
            pad,
            pad,
            pad + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _AppLockCard(),
            SizedBox(height: 16.w),
            _PrivacyCard(),
            SizedBox(height: 16.w),
            _DataCard(),
          ],
        ),
      ),
    );
  }
}

final class _AppLockCard extends StatelessWidget {
  const _AppLockCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        final settings = state.settings;
        return GlassSurface.fake(
          borderRadius: AppRadius.card,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('App lock'),
                subtitle: const Text(
                  'Require biometrics or device PIN to open',
                ),
                value: settings.appLock,
                onChanged: (value) => _toggleLock(context, value),
              ),
              Divider(height: 32.w),
              DropdownButtonFormField<LockTimeout>(
                initialValue: settings.lockTimeout,
                decoration: const InputDecoration(labelText: 'Lock after'),
                items: [
                  for (final option in LockTimeout.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: settings.appLock
                    ? (value) {
                        if (value != null) {
                          context.read<SecurityCubit>().setLockTimeout(value);
                        }
                      }
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLock(BuildContext context, bool value) async {
    final cubit = context.read<SecurityCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await cubit.setAppLock(value);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Set up a screen lock or biometrics first'),
        ),
      );
    }
  }
}

final class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        final settings = state.settings;
        final cubit = context.read<SecurityCubit>();
        return GlassSurface.fake(
          borderRadius: AppRadius.card,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Block screenshots'),
                subtitle: const Text(
                  'Hide Aura from screenshots and recent apps',
                ),
                value: settings.blockScreenshots,
                onChanged: cubit.setBlockScreenshots,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pause listening history'),
                subtitle: const Text(
                  'Stop adding played tracks to your history',
                ),
                value: settings.pauseHistory,
                onChanged: cubit.setPauseHistory,
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_toggle_off),
            title: const Text('Clear search history'),
            subtitle: const Text('Remove your recent search terms'),
            onTap: () => _clearSearches(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever_outlined),
            title: const Text('Clear all data'),
            subtitle: const Text('Delete library, downloads and settings'),
            onTap: () => _clearAll(context),
          ),
          Divider(height: 24.w),
          Text(
            'Aura stores your library, history and downloads only on this '
            'device. Nothing is uploaded, and no analytics or trackers are '
            'included. Audio is streamed directly from the public catalog.',
          ),
          SizedBox(height: 12.w),
        ],
      ),
    );
  }

  Future<void> _clearSearches(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear search history?',
      message: 'Your recent search terms will be removed from this device.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    await getIt<ClearRecentSearches>().call(const NoParams());
  }

  Future<void> _clearAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showTypedConfirmDialog(
      context,
      title: 'Clear all data?',
      message:
          'This deletes your likes, playlists, history, downloads and '
          'settings from this device. This cannot be undone.',
      keyword: 'DELETE',
      confirmLabel: 'Delete everything',
    );
    if (!confirmed) return;
    await getIt<DataResetService>().clearAll();
    messenger.showSnackBar(
      const SnackBar(content: Text('All local data cleared')),
    );
  }
}
