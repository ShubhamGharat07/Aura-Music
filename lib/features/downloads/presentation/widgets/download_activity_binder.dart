import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/app_notification_service.dart';
import 'package:aura_music/core/services/permission_service.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';

/// Mirrors download activity into a single, throttled system notification.
///
/// A whole batch shares one notification: progress is coalesced to whole
/// percent steps, completion/failure replaces it, so the shade never fills up
/// with one entry per track (best practice for background transfers).
final class DownloadActivityBinder extends HookWidget {
  /// Wraps [child].
  const DownloadActivityBinder({required this.child, super.key});

  /// App subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final notifications = getIt<AppNotificationService>();
    final lastPercent = useRef<int?>(null);
    final wasActive = useRef(false);
    final activeTitle = useRef<String?>(null);
    final failuresAtStart = useRef(0);
    final pausedAtStart = useRef(0);
    final completedAtStart = useRef(0);
    final permissionRequested = useRef(false);

    useEffect(() {
      unawaited(notifications.init());
      return null;
    }, [notifications]);

    return BlocListener<DownloadsCubit, DownloadsState>(
      listenWhen: (previous, current) =>
          previous.downloads != current.downloads,
      listener: (context, state) {
        final active = state.downloads
            .where(
              (download) =>
                  download.status == DownloadStatus.downloading ||
                  download.status == DownloadStatus.queued,
            )
            .toList(growable: false);

        if (active.isEmpty) {
          if (!wasActive.value) return;
          wasActive.value = false;
          final shownProgress = lastPercent.value != null;
          final finishedTitle = activeTitle.value;
          lastPercent.value = null;
          activeTitle.value = null;
          if (!shownProgress) return;
          final failures = state.downloads
              .where((download) => download.status == DownloadStatus.failed)
              .length;
          final paused = state.downloads
              .where((download) => download.status == DownloadStatus.paused)
              .length;
          final offlineCount = state.downloads
              .where((download) => download.isComplete)
              .length;
          if (failures > failuresAtStart.value) {
            unawaited(notifications.showDownloadFailed());
          } else if (offlineCount > completedAtStart.value) {
            unawaited(
              notifications.showDownloadsComplete(
                offlineCount: offlineCount,
                trackTitle: finishedTitle,
              ),
            );
          } else if (paused > pausedAtStart.value) {
            unawaited(notifications.showDownloadsPaused());
          } else {
            unawaited(notifications.clearDownloadNotification());
          }
          return;
        }

        if (!wasActive.value) {
          wasActive.value = true;
          lastPercent.value = null;
          failuresAtStart.value = state.downloads
              .where((download) => download.status == DownloadStatus.failed)
              .length;
          pausedAtStart.value = state.downloads
              .where((download) => download.status == DownloadStatus.paused)
              .length;
          completedAtStart.value = state.downloads
              .where((download) => download.isComplete)
              .length;
          if (!permissionRequested.value) {
            permissionRequested.value = true;
            unawaited(getIt<PermissionService>().requestNotification());
          }
        }

        final totalBytes = active.fold<int>(
          0,
          (sum, download) => sum + download.totalBytes,
        );
        final downloadedBytes = active.fold<int>(
          0,
          (sum, download) => sum + download.bytesDownloaded,
        );
        final percent = totalBytes > 0
            ? ((downloadedBytes / totalBytes) * 100).floor().clamp(0, 100)
            : -1;
        if (percent == lastPercent.value) return;
        lastPercent.value = percent;

        final title = active.length == 1 ? active.first.track.title : null;
        activeTitle.value = title;
        unawaited(
          notifications.showDownloadProgress(
            activeCount: active.length,
            trackTitle: title,
            percent: percent,
          ),
        );
      },
      child: child,
    );
  }
}
