import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aura_music/app.dart';
import 'package:aura_music/bootstrap.dart';
import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/router/app_router.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/services/app_notification_service.dart';

/// Entry point. All init lives in [bootstrap]; no logic here.
Future<void> main() async {
  await bootstrap();
  final router = buildRouter();
  final notifications = getIt<AppNotificationService>();
  notifications.bindUpdateNavigation(() {
    if (router.routeInformationProvider.value.uri.path !=
        AppRoutes.settingsUpdates) {
      router.go(AppRoutes.settingsUpdates);
    }
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(notifications.init());
  });
  runApp(AuraApp(router: router));
}
