import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed_view.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';

/// Home tab root. Owns the [HomeBloc] (feed sections) and a
/// [PlaylistsCubit] for "Your playlists", then delegates layout.
final class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: HomeFeedView(
        layout: sizeClass == WindowSizeClass.compact
            ? const HomeFeedLayout.compact()
            : const HomeFeedLayout.wide(),
        showRecentlyPlayed: sizeClass == WindowSizeClass.large,
      ),
    );
  }
}
