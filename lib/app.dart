import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/screen_scale.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/services/connectivity_cubit.dart';
import 'package:aura_music/core/theme/app_theme.dart';
import 'package:aura_music/core/ui/dynamic_accent_binder.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/downloads/presentation/widgets/download_activity_binder.dart';
import 'package:aura_music/features/downloads/presentation/widgets/downloads_network_binder.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/widgets/playback_settings_binder.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';
import 'package:aura_music/features/security/presentation/widgets/app_lock_gate.dart';
import 'package:aura_music/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:aura_music/l10n/generated/app_localizations.dart';

/// Root widget. ScreenUtil design size follows the device class
/// (PRD 7.3): 393x852 / 744x1133 / 1194x834, text clamped 0.9-1.25x.
final class AuraApp extends StatelessWidget {
  const AuraApp({super.key, required this.router});

  final GoRouter router;

  /// Portrait design draft for a device whose shortest side is [shortestSide].
  /// Class comes from the shortest side so a rotation cannot change it.
  static Size designFor(double shortestSide) {
    return switch (WindowSizeClass.ofWidth(shortestSide)) {
      WindowSizeClass.compact => const Size(393, 852),
      WindowSizeClass.medium => const Size(744, 1133),
      WindowSizeClass.expanded ||
      WindowSizeClass.large => const Size(1194, 834),
    };
  }

  /// Draft for the current window: portrait normally, sides swapped when the
  /// window is landscape. Keeps the scale factor ~1x in both orientations, so
  /// rotating never balloons or cramps the UI.
  static Size designForSize(Size size) {
    final portrait = designFor(size.shortestSide);
    return size.width > size.height
        ? Size(portrait.height, portrait.width)
        : portrait;
  }

  @override
  Widget build(BuildContext context) {
    final view = View.maybeOf(context);
    final app = MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<SettingsCubit>()),
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<ConnectivityCubit>()),
        BlocProvider.value(value: getIt<PlayerBloc>()),
        BlocProvider.value(value: getIt<DownloadsCubit>()),
        BlocProvider.value(value: getIt<SecurityCubit>()),
      ],
      child: Builder(
        builder: (context) {
          final logical = MediaQuery.sizeOf(context);
          final design = designForSize(logical);
          return ScreenScale(
            designSize: design,
            // Keep the scale config outside the theme rebuild: reapplying it
            // on every appearance toggle made the switch animation stutter.
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, theme) => MaterialApp.router(
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context).appTitle,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                debugShowCheckedModeBanner: false,
                theme: buildDarkTheme(
                  accent: theme.accent,
                  amoled: theme.amoled,
                ),
                themeAnimationDuration: const Duration(milliseconds: 120),
                themeAnimationCurve: Curves.easeOut,
                routerConfig: router,
                builder: (context, child) => PlaybackSettingsBinder(
                  child: DownloadsNetworkBinder(
                    child: DownloadActivityBinder(
                      child: DynamicAccentBinder(
                        child: AppLockGate(
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    if (view == null) return app;
    // Own the MediaQuery so the new logical size is available during the same
    // build phase as the rotation. No curtain, timer or forced wait is added:
    // the new constraints lay out immediately, while router branches, BLoCs
    // and the player stay mounted.
    return MediaQuery.fromView(view: view, child: app);
  }
}
