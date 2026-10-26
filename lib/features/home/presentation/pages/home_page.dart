import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed_view.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';

/// Home tab root (PRD S03). Thin page: owns the [HomeBloc] (feed sections)
/// and a [PlaylistsCubit] for "Your playlists", then delegates layout.

/// Home tab root.
final class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Home carries more small metadata than the other tabs (artist names,
    // card captions, chip labels), so give its whole subtree a slightly
    // larger text scale instead of bumping shared tokens everywhere. The
    // device's own accessibility scale is preserved and multiplied.
    final media = MediaQuery.of(context);
    final sizeClass = WindowSizeClass.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
        ),
        BlocProvider<PlaylistsCubit>(
          create: (_) => getIt<PlaylistsCubit>()..load(),
        ),
      ],
      child: MediaQuery(
        data: media.copyWith(textScaler: _HomeTextScaler(media.textScaler)),
        child: HomeFeedView(
          layout: sizeClass == WindowSizeClass.compact
              ? const HomeFeedLayout.compact()
              : const HomeFeedLayout.wide(),
          showRecentlyPlayed: sizeClass == WindowSizeClass.large,
        ),
      ),
    );
  }
}

/// Home-only text scale: about +1 dp on captions and +2 dp on section titles.
final class _HomeTextScaler extends TextScaler {
  const _HomeTextScaler(this._device);

  static const double _boost = 1.08;

  final TextScaler _device;

  @override
  double scale(double fontSize) => _device.scale(fontSize) * _boost;

  // Kept for legacy text APIs; derived from scale() to avoid the deprecated
  // textScaleFactor getter on the wrapped scaler.
  @override
  double get textScaleFactor => _device.scale(1) * _boost;

  @override
  bool operator ==(Object other) =>
      other is _HomeTextScaler && other._device == _device;

  @override
  int get hashCode => Object.hash(_HomeTextScaler, _device);
}
