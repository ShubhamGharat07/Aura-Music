import 'package:flutter/material.dart';

import 'package:aura_music/app.dart';
import 'package:aura_music/bootstrap.dart';
import 'package:aura_music/core/router/app_router.dart';

/// Entry point. All init lives in [bootstrap]; no logic here.
Future<void> main() async {
  await bootstrap();
  runApp(AuraApp(router: buildRouter()));
}
