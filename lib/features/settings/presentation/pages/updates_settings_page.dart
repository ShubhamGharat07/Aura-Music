import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/app_notification_service.dart';
import 'package:aura_music/core/services/installer_service.dart';
import 'package:aura_music/core/services/update_downloads.dart';
import 'package:aura_music/core/services/update_service.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Android OTA settings, release notes and installation controls.
final class UpdatesSettingsPage extends HookWidget {
  const UpdatesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final info = useFuture(useMemoized(PackageInfo.fromPlatform));
    final service = _registered<UpdateService>();
    final supported = service?.supported == true;
    useListenable(service?.latest);
    final update = service?.latest.value;
    final checking = useState(false);
    final failed = useState(false);
    final showSkipped = useState(false);
    final skippedHere = useState<int?>(null);
    final autoChecks = useState(service?.automaticChecks ?? true);
    final updateAlerts = useState(service?.updateAlerts ?? true);

    useEffect(() {
      if (!supported) return null;
      // The service can finish independently if Settings closes mid-check.
      service!.checkAndNotify();
      return null;
    }, [service, supported]);

    Future<void> check() async {
      if (checking.value) return;
      checking.value = true;
      failed.value = false;
      showSkipped.value = true;
      final result = await service!.check();
      if (!context.mounted) return;
      failed.value = result == null;
      checking.value = false;
    }

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
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.system_update_rounded),
                    title: Text('Aura Music', style: AppTypography.title),
                    subtitle: Text(
                      info.hasData
                          ? 'Installed: v${info.data!.version} (${info.data!.buildNumber})'
                          : 'Installed version unavailable',
                    ),
                  ),
                  if (supported)
                    FilledButton.icon(
                      onPressed: checking.value ? null : check,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        checking.value
                            ? 'Checking for updates?'
                            : 'Check for updates',
                      ),
                    )
                  else
                    const Text('In-app APK updates are available on Android.'),
                ],
              ),
            ),
            if (supported) ...[
              SizedBox(height: AppSpacing.md),
              if (failed.value)
                const _UpdateMessage(
                  'Could not check for updates. Check your connection and try again.',
                ),
              if (update != null)
                if (update.isUpdateAvailable)
                  if ((!service!.isSkipped(update) &&
                          skippedHere.value != update.versionCode) ||
                      showSkipped.value)
                    _AvailableUpdate(
                      key: ValueKey((update.versionCode, update.asset!.sha256)),
                      update: update,
                      downloads: getIt<UpdateDownloads>(),
                      installer: getIt<InstallerService>(),
                      onSkip: () async {
                        await service.skip(update);
                        if (context.mounted) {
                          skippedHere.value = update.versionCode;
                          showSkipped.value = false;
                        }
                      },
                    )
                  else
                    const _UpdateMessage(
                      'This update was skipped. Check for updates to see it again.',
                    )
                else
                  _UpdateMessage(
                    update.unavailableReason ?? 'Aura Music is up to date.',
                  ),
              SizedBox(height: AppSpacing.md),
              GlassSurface.fake(
                borderRadius: AppRadius.card,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Check automatically'),
                      value: autoChecks.value,
                      onChanged: (value) async {
                        autoChecks.value = value;
                        await service!.setAutomaticChecks(value);
                        if (value) await service.checkAndNotify();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Update notifications'),
                      value: updateAlerts.value,
                      onChanged: (value) async {
                        if (value &&
                            !await getIt<AppNotificationService>()
                                .requestUpdateNotificationPermission()) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Allow notifications in Android settings.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        if (!context.mounted) return;
                        updateAlerts.value = value;
                        await service!.setUpdateAlerts(value);
                      },
                    ),
                    if (updateAlerts.value)
                      ListTile(
                        title: const Text('Allow Android notifications'),
                        onTap: () async {
                          final granted = await getIt<AppNotificationService>()
                              .requestUpdateNotificationPermission();
                          if (granted) await service!.setUpdateAlerts(true);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

T? _registered<T extends Object>() =>
    getIt.isRegistered<T>() ? getIt<T>() : null;

final class _UpdateMessage extends StatelessWidget {
  const _UpdateMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => GlassSurface.fake(
    margin: EdgeInsets.only(bottom: AppSpacing.sm),
    padding: EdgeInsets.all(AppSpacing.md),
    child: Text(message, style: AppTypography.body),
  );
}

final class _AvailableUpdate extends HookWidget {
  const _AvailableUpdate({
    super.key,
    required this.update,
    required this.downloads,
    required this.installer,
    required this.onSkip,
  });

  final UpdateInfo update;
  final UpdateDownloads downloads;
  final InstallerService installer;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final stream = useMemoized(() => downloads.watch(update));
    final snapshot = useStream(stream);
    final state = snapshot.data;
    final busy = useState(false);
    final error = useState<String?>(null);

    Future<void> run(Future<void> Function() operation) async {
      if (busy.value) return;
      busy.value = true;
      error.value = null;
      try {
        await operation();
      } on PlatformException catch (failure) {
        if (context.mounted) {
          error.value = failure.message ?? 'Could not open Android installer.';
        }
      } on StateError catch (failure) {
        if (context.mounted) error.value = failure.message;
      } on Object {
        if (context.mounted) {
          error.value = 'Could not complete the update action.';
        }
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    Future<void> install() async {
      if (!await installer.canInstallUnknownSources()) {
        if (!await installer.openInstallPermissionSettings()) {
          throw StateError(
            'Open Android settings to allow Aura Music to install updates.',
          );
        }
        return;
      }
      if (!await downloads.install(update)) {
        throw StateError('Could not open Android installer.');
      }
    }

    final asset = update.asset!;
    final notes = update.releaseNotes?.trim();
    final megabytes = (asset.size / (1024 * 1024)).toStringAsFixed(1);
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update available', style: AppTypography.title),
          SizedBox(height: AppSpacing.xs),
          Text(
            'v${update.latestVersion} ? Build ${update.versionCode} ? $megabytes MB',
          ),
          if (notes != null && notes.isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            Text('What?s new', style: AppTypography.subtitle),
            SizedBox(height: AppSpacing.xs),
            Text(notes, style: AppTypography.body),
          ],
          SizedBox(height: AppSpacing.md),
          if (error.value != null)
            Text(
              error.value!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (snapshot.hasError)
            const Text(
              'Download status is unavailable. Reopen Updates to retry.',
            )
          else if (state == null)
            const LinearProgressIndicator()
          else
            switch (state.phase) {
              UpdateDownloadPhase.downloading => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress : null,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Downloading ? ${(state.progress * 100).round()}%'),
                      TextButton(
                        onPressed: busy.value
                            ? null
                            : () => run(() async {
                                if (!await downloads.cancel(update)) {
                                  throw StateError(
                                    'Could not cancel the download.',
                                  );
                                }
                              }),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
              UpdateDownloadPhase.ready => FilledButton.icon(
                onPressed: busy.value ? null : () => run(install),
                icon: const Icon(Icons.install_mobile_rounded),
                label: Text(
                  busy.value ? 'Verifying APK?' : 'Verify and install',
                ),
              ),
              UpdateDownloadPhase.idle ||
              UpdateDownloadPhase.paused ||
              UpdateDownloadPhase.failed => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: busy.value
                        ? null
                        : () => run(() => downloads.start(update)),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(switch (state.phase) {
                      UpdateDownloadPhase.paused => 'Resume download',
                      UpdateDownloadPhase.failed => 'Retry download',
                      _ => 'Download update',
                    }),
                  ),
                  if (state.phase == UpdateDownloadPhase.paused)
                    TextButton(
                      onPressed: busy.value
                          ? null
                          : () => run(() async {
                              if (!await downloads.cancel(update)) {
                                throw StateError(
                                  'Could not cancel the download.',
                                );
                              }
                            }),
                      child: const Text('Cancel'),
                    )
                  else
                    TextButton(
                      onPressed: busy.value ? null : () => run(onSkip),
                      child: const Text('Skip this version'),
                    ),
                ],
              ),
            },
        ],
      ),
    );
  }
}
