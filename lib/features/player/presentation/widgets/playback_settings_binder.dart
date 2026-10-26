import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';

/// Applies the persisted audio settings (speed, skip silence) to the shared
/// [PlaybackController] (PRD S18), and re-applies them whenever the user
/// changes them in Settings → Audio & EQ.
final class PlaybackSettingsBinder extends HookWidget {
  /// Creates the binder.
  const PlaybackSettingsBinder({super.key, required this.child});

  /// App subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final speed = context.select(
      (SettingsCubit cubit) => cubit.state.settings.playbackSpeed,
    );
    final skipSilence = context.select(
      (SettingsCubit cubit) => cubit.state.settings.skipSilence,
    );
    useEffect(() {
      final controller = _controller();
      if (controller == null) return null;
      unawaited(controller.setSpeed(speed));
      unawaited(controller.setSkipSilence(skipSilence));
      return null;
    }, [speed, skipSilence]);
    return child;
  }

  static PlaybackController? _controller() {
    try {
      return getIt<PlaybackController>();
    } on Object {
      return null;
    }
  }
}
