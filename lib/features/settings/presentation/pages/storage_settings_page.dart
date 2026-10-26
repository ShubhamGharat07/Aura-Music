import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/app_dialog.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/utils/formatters.dart';
import 'package:aura_music/features/downloads/domain/entities/download_summary.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';

/// Storage & downloads settings (PRD S19): offline space used and cleanup.

/// Storage sub-page.
final class StorageSettingsPage extends StatelessWidget {
  /// Creates the storage page.
  const StorageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: const Text('Storage & downloads')),
      body: MaxContentWidth(
        child: BlocBuilder<DownloadsCubit, DownloadsState>(
          builder: (context, state) {
            final summary = DownloadSummary.of(state.downloads);
            return ListView(
              padding: EdgeInsets.fromLTRB(
                pad,
                pad,
                pad,
                pad + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _UsageCard(summary: summary),
                SizedBox(height: 12.w),
                _Actions(summary: summary),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.summary});

  final DownloadSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offline library',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.w),
          Text(
            '${summary.completed} of ${summary.total} tracks available offline',
          ),
          SizedBox(height: 4.w),
          Text('${formatBytes(summary.bytesUsed)} used on this device'),
          if (summary.inProgress > 0) ...[
            SizedBox(height: 4.w),
            Text('${summary.inProgress} download(s) in progress'),
          ],
          if (summary.failed > 0) ...[
            SizedBox(height: 4.w),
            Text(
              '${summary.failed} failed',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

final class _Actions extends StatelessWidget {
  const _Actions({required this.summary});

  final DownloadSummary summary;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.symmetric(vertical: 4.w),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Manage downloads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.downloads),
          ),
          ListTile(
            enabled: summary.total > 0,
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Remove all downloads'),
            onTap: summary.total == 0 ? null : () => _confirmClear(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<DownloadsCubit>();
    final ids = cubit.state.downloads
        .map((d) => d.track.id)
        .toList(growable: false);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove all downloads?',
      message: 'This deletes ${ids.length} offline track(s) from this device.',
      confirmLabel: 'Remove',
    );
    if (confirmed) {
      for (final id in ids) {
        await cubit.remove(id);
      }
    }
  }
}
