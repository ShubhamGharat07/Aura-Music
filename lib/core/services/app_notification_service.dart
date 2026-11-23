import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// App-owned local notifications that are *not* the media session (PRD S14).
///
/// The media notification is owned by `audio_service`; this service covers
/// download progress/completion. Every call is best-effort: notifications are
/// an enhancement, so a missing plugin, revoked permission or platform error
/// must never interrupt playback or downloading.
final class AppNotificationService {
  /// Creates the service around [plugin] (injectable for tests).
  AppNotificationService(this._plugin);

  static const int _downloadId = 4201;
  static const String _downloadChannelId = 'aura.downloads';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Progress and completion of offline downloads';

  static const int _updateId = 4202;
  static const String _updateChannelId = 'aura.updates';
  static const String _updateChannelName = 'App Updates';
  static const String _updateChannelDescription =
      'Notifications for new app updates and releases';

  static const _updatesPayload = 'aura:updates';

  final FlutterLocalNotificationsPlugin _plugin;
  VoidCallback? _updateNavigation;
  bool _pendingUpdateNavigation = false;

  void bindUpdateNavigation(VoidCallback callback) {
    _updateNavigation = callback;
    if (_pendingUpdateNavigation) openUpdates();
  }

  void openUpdates() {
    final navigate = _updateNavigation;
    _pendingUpdateNavigation = navigate == null;
    navigate?.call();
  }

  void _onResponse(NotificationResponse response) {
    if (response.payload == _updatesPayload) openUpdates();
  }

  Future<bool> requestUpdateNotificationPermission() async {
    if (!await _ensureReady()) return false;
    try {
      final android = _android;
      if (android == null) return false;
      return await android.areNotificationsEnabled() == true ||
          await android.requestNotificationsPermission() == true;
    } on Object {
      return false;
    }
  }

  Future<void>? _initFuture;
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Initialises the plugin and its channels. Safe to await repeatedly.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_aura'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onResponse,
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _downloadChannelId,
          _downloadChannelName,
          description: _downloadChannelDescription,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _updateChannelId,
          _updateChannelName,
          description: _updateChannelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && response != null) {
        _onResponse(response);
      }
    } on Object catch (error, stack) {
      _ready = false;
      if (kDebugMode) {
        debugPrint('Notifications unavailable: $error\n$stack');
      }
    }
  }

  /// Shows/replaces the aggregate progress notification.
  ///
  /// [percent] is 0-100, or negative when the total size is still unknown.
  Future<void> showDownloadProgress({
    required int activeCount,
    required String? trackTitle,
    required int percent,
  }) async {
    if (!await _ensureReady()) return;
    final unknown = percent < 0;
    final safePercent = unknown ? 0 : percent.clamp(0, 100);
    final body = unknown
        ? (trackTitle ?? 'Preparing your offline library')
        : '${trackTitle ?? 'Preparing your offline library'}'
              ' \u00B7 $safePercent%';
    try {
      await _plugin.show(
        id: _downloadId,
        title: activeCount == 1
            ? 'Downloading 1 track'
            : 'Downloading $activeCount tracks',
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            icon: 'ic_stat_aura',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showProgress: true,
            indeterminate: unknown,
            maxProgress: 100,
            progress: safePercent,
          ),
        ),
      );
    } on Object {
      // Best-effort only.
    }
  }

  /// Replaces the progress notification with a quiet completion summary.
  Future<void> showDownloadsComplete({
    required int offlineCount,
    String? trackTitle,
  }) async {
    if (!await _ensureReady()) return;
    final body = trackTitle != null && offlineCount == 1
        ? '$trackTitle is available offline'
        : '$offlineCount tracks available offline';
    await _showDownloadResult(title: 'Download complete', body: body);
  }

  /// Replaces the progress notification when downloads were paused.
  Future<void> showDownloadsPaused() async {
    if (!await _ensureReady()) return;
    await _showDownloadResult(
      title: 'Downloads paused',
      body: 'They resume automatically when you are back online.',
    );
  }

  /// Replaces the progress notification when a download failed.
  Future<void> showDownloadFailed() async {
    if (!await _ensureReady()) return;
    await _showDownloadResult(
      title: 'Download failed',
      body: 'Open Downloads to retry.',
    );
  }

  Future<void> _showDownloadResult({
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id: _downloadId,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            icon: 'ic_stat_aura',
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: true,
          ),
        ),
      );
    } on Object {
      // Best-effort only.
    }
  }

  /// Shows a notification when a new app version is available.
  Future<bool> showUpdateAvailable({
    required String version,
    required String? releaseTitle,
  }) async {
    if (!await _ensureReady()) return false;
    try {
      if (await _android?.areNotificationsEnabled() != true) return false;
      await _plugin.show(
        id: _updateId,
        title: 'Aura Music update available',
        body:
            'v$version ? ${releaseTitle ?? "Open Updates for the changelog."}',
        payload: _updatesPayload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _updateChannelId,
            _updateChannelName,
            channelDescription: _updateChannelDescription,
            icon: 'ic_stat_aura',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> clearUpdateAvailable() async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.cancel(id: _updateId);
    } on Object {
      // Best-effort only.
    }
  }

  /// Removes the download notification (e.g. when the list is cleared).
  Future<void> clearDownloadNotification() async {
    try {
      await _plugin.cancel(id: _downloadId);
    } on Object {
      // Best-effort only.
    }
  }

  Future<bool> _ensureReady() async {
    await init();
    return _ready;
  }
}
