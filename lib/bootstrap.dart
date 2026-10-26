import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/audio_session_service.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/services/playback/media_session_service.dart';
import 'package:aura_music/core/services/secure_key_service.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/features/home/domain/usecases/get_home_trending.dart';
import 'package:aura_music/features/home/domain/usecases/get_new_releases.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';

/// Async startup: bindings -> DI -> tier probe -> secure key -> settings.
/// Returns the router-ready database handle for queue restore (Phase 1).
Future<AppDatabase> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<SecureKeyService>().getOrCreateKey();
  await getIt<AudioSessionService>().configure();
  await getIt<MediaSessionService>().start();
  await getIt<DeviceTierService>().probe();
  await getIt<SettingsCubit>().load();
  await getIt<SecurityCubit>().load();
  final settings = getIt<SettingsCubit>().state.settings;
  getIt<ThemeCubit>().setAmoled(settings.amoled);
  // Brings the last queue + position back, paused (PRD S06). Used to run while
  // the splash was on screen; with no splash it starts here instead.
  getIt<PlayerBloc>().add(const PlayerSessionRestoreRequested());
  _warmHomeFeed();
  return getIt<AppDatabase>();
}

/// Fire-and-forget: fills the home feed cache so the first Home paint shows
/// content instead of skeletons. Deferred to after the first frame so the
/// splash entrance stays smooth (the requests don't compete with first paint).
void _warmHomeFeed() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(getIt<GetHomeTrending>().call(20));
    unawaited(getIt<GetNewReleases>().call(20));
  });
}
