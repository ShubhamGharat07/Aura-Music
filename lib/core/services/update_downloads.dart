import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/services/installer_service.dart';
import 'package:aura_music/core/services/update_manifest.dart';
import 'package:aura_music/core/services/update_service.dart';

enum UpdateDownloadPhase { idle, downloading, paused, ready, failed }

typedef UpdateDownload = ({UpdateDownloadPhase phase, double progress});

/// Tracks Android background downloads independently of the Updates screen.
final class UpdateDownloads {
  UpdateDownloads(this._installer, {required this.openUpdates});

  final InstallerService _installer;
  final void Function() openUpdates;
  static const _group = 'aura-ota';
  static const directory = 'ota';

  FileDownloader get _downloader => FileDownloader();
  Future<void>? _initializing;
  bool _starting = false;

  Future<void> initialize() =>
      _initializing ??= _initialize().onError<Object>((error, stack) {
        _initializing = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _initialize() async {
    _downloader.registerCallbacks(
      group: _group,
      taskNotificationTapCallback: (_, _) => openUpdates(),
    );
    _downloader.configureNotificationForGroup(
      _group,
      running: const TaskNotification('Downloading Aura Music', '{progress}'),
      paused: const TaskNotification(
        'Aura Music update paused',
        'Resume or cancel',
      ),
      complete: const TaskNotification(
        'Aura Music download finished',
        'Open Updates to verify and install',
      ),
      error: const TaskNotification(
        'Aura Music download failed',
        'Open Updates to retry',
      ),
      progressBar: true,
    );
    await _downloader.trackTasksInGroup(_group);
    await _downloader.resumeFromBackground();
    await _pruneInstalledUpdates();
    // Give Android a chance to republish the status of pending jobs first.
    Timer(const Duration(seconds: 5), () async {
      try {
        await _downloader.rescheduleKilledTasks();
      } on Object {
        // The user can retry from the Updates screen.
      }
    });
  }

  Future<void> _pruneInstalledUpdates() async {
    final installed = int.tryParse(
      (await PackageInfo.fromPlatform()).buildNumber,
    );
    if (installed == null) return;
    for (final record in await _downloader.database.allRecords(group: _group)) {
      final code = int.tryParse(record.task.metaData);
      if (code == null || code > installed) continue;
      if (record.status.isNotFinalState &&
          !await _downloader.cancelTaskWithId(record.taskId)) {
        continue;
      }
      await _deleteIfPresent(File(await record.task.filePath()));
      await _downloader.database.deleteRecordWithId(record.taskId);
    }
  }

  DownloadTask _task(UpdateInfo update) {
    final asset = update.asset;
    final url = update.downloadUri;
    if (asset == null || url == null) {
      throw StateError('This release has no compatible APK.');
    }
    final id = 'aura-${update.versionCode}-${asset.sha256}';
    return DownloadTask(
      taskId: id,
      url: url.toString(),
      filename: '$id.apk',
      directory: directory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: _group,
      updates: Updates.statusAndProgress,
      allowPause: true,
      metaData: update.versionCode.toString(),
      retries: 2,
    );
  }

  Stream<UpdateDownload> watch(UpdateInfo update) =>
      Stream.multi((output) async {
        StreamSubscription<TaskRecord>? subscription;
        var canceled = false;
        output.onCancel = () async {
          canceled = true;
          await subscription?.cancel();
        };
        try {
          await initialize();
          if (canceled) return;
          final taskId = _task(update).taskId;
          var receivedUpdate = false;
          subscription = _downloader.database.updates.listen((record) {
            if (record.taskId != taskId) return;
            receivedUpdate = true;
            output.add(_state(record));
          }, onError: output.addError);
          final record = await _downloader.database.recordForId(taskId);
          if (!receivedUpdate && !canceled) output.add(_state(record));
        } on Object catch (error, stack) {
          if (!canceled) output.addError(error, stack);
        }
      });

  Future<void> start(UpdateInfo update) async {
    if (_starting) return;
    _starting = true;
    try {
      await initialize();
      final task = _task(update);
      final record = await _downloader.database.recordForId(task.taskId);
      if (record?.status == TaskStatus.paused) {
        if (await _downloader.resume(task)) return;
      } else if (record?.status == TaskStatus.complete ||
          (record != null && record.status.isNotFinalState) ||
          await _downloader.taskForId(task.taskId) != null) {
        return;
      }
      final free = await _installer.availableBytes();
      if (free < update.asset!.size * AppConstants.updateFreeSpaceFactor) {
        throw StateError('Not enough free storage to download this update.');
      }
      // Keep a single active APK and remove obsolete private artifacts.
      for (final old in await _downloader.database.allRecords(group: _group)) {
        if (old.taskId == task.taskId) continue;
        if (old.status.isNotFinalState) {
          if (!await _downloader.cancelTaskWithId(old.taskId)) {
            throw StateError('Cancel the previous download before retrying.');
          }
        }
        await _deleteIfPresent(File(await old.task.filePath()));
        await _downloader.database.deleteRecordWithId(old.taskId);
      }
      await _deleteIfPresent(File(await task.filePath()));
      if (!await _downloader.enqueue(task)) {
        throw StateError('Could not start the APK download.');
      }
    } finally {
      _starting = false;
    }
  }

  Future<bool> cancel(UpdateInfo update) async {
    await initialize();
    return _downloader.cancelTaskWithId(_task(update).taskId);
  }

  /// Validates the staged APK again on every installation attempt.
  Future<bool> install(UpdateInfo update) async {
    await initialize();
    final task = _task(update);
    final record = await _downloader.database.recordForId(task.taskId);
    if (record?.status != TaskStatus.complete) return false;
    final file = File(await task.filePath());
    if (!await verifyUpdateApk(file, update.asset!)) {
      await _deleteIfPresent(file);
      await _downloader.database.updateRecord(
        TaskRecord(task, TaskStatus.failed, 0, update.asset!.size),
      );
      throw StateError('APK verification failed. Download it again.');
    }
    return _installer.installApk(file.path, versionCode: update.versionCode);
  }

  static UpdateDownload _state(TaskRecord? record) {
    final phase = switch (record?.status) {
      TaskStatus.enqueued ||
      TaskStatus.running ||
      TaskStatus.waitingToRetry => UpdateDownloadPhase.downloading,
      TaskStatus.paused => UpdateDownloadPhase.paused,
      TaskStatus.complete => UpdateDownloadPhase.ready,
      TaskStatus.failed || TaskStatus.notFound => UpdateDownloadPhase.failed,
      _ => UpdateDownloadPhase.idle,
    };
    return (phase: phase, progress: (record?.progress ?? 0).clamp(0.0, 1.0));
  }

  static Future<void> _deleteIfPresent(File file) async {
    if (await file.exists()) await file.delete();
  }
}

/// Checks size and SHA-256 without loading the full APK into memory.
Future<bool> verifyUpdateApk(File file, UpdateAsset asset) async {
  if (!await file.exists() || await file.length() != asset.size) return false;
  final digest = await sha256.bind(file.openRead()).single;
  return digest.toString() == asset.sha256;
}
