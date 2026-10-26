import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/dynamic_accent_service.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';

/// Pushes the playing track's artwork accent into [ThemeCubit] (PRD F06).
///
/// Sits under the BLoC providers but above the router, so it listens to the
/// player without rebuilding any page: only the MaterialApp theme changes.
/// When the user turns dynamic colour off or nothing is playing, the accent
/// returns to the brand default.
final class DynamicAccentBinder extends HookWidget {
  /// Creates the binder.
  const DynamicAccentBinder({super.key, required this.child});

  /// App subtree (the router).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final artUrl = context.select(
      (PlayerBloc bloc) => bloc.state.currentTrack?.artUrl,
    );
    final enabled = context.select(
      (SettingsCubit cubit) => cubit.state.settings.dynamicColor,
    );
    final theme = context.read<ThemeCubit>();

    useEffect(() {
      final url = artUrl;
      if (!enabled || url == null || url.isEmpty) {
        theme.setAccent(AppColors.accentDefault);
        return null;
      }
      var cancelled = false;
      unawaited(
        _accentFor(url).then((color) {
          if (!cancelled && color != null) theme.setAccent(color);
        }),
      );
      return () => cancelled = true;
    }, [artUrl, enabled, theme]);

    return child;
  }

  static Future<Color?> _accentFor(String artUrl) async {
    try {
      return await getIt<DynamicAccentService>().accentFor(artUrl);
    } on Object {
      return null;
    }
  }
}
