import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed.dart';
import 'package:aura_music/features/home/presentation/widgets/home_recently_played.dart';

/// Single home scroll view shared by every window class.
///
/// Keeping one [CustomScrollView] at a stable tree position lets the feed keep
/// its scroll offset when a rotation swaps compact and wide metrics; swapping
/// two different widgets used to dispose the old scrollable before the new one
/// could read its [PageStorage] offset.
final class HomeFeedView extends StatelessWidget {
  /// Creates the shared home feed.
  const HomeFeedView({
    super.key,
    required this.layout,
    this.showRecentlyPlayed = false,
  });

  /// Per-window-class metrics.
  final HomeFeedLayout layout;

  /// Show the Recently-played column (Large only).
  final bool showRecentlyPlayed;

  @override
  Widget build(BuildContext context) {
    final feed = RefreshIndicator(
      onRefresh: () => context.read<HomeBloc>().refresh(),
      child: BlocBuilder<HomeBloc, HomeState>(
        // The feed structure only depends on these fields. Section data is
        // subscribed to by each section individually, so an async section
        // arriving does not rebuild and relayout the whole scroll view.
        buildWhen: (previous, current) =>
            previous.offline != current.offline ||
            previous.selectedGenre != current.selectedGenre ||
            previous.selectedLanguage != current.selectedLanguage ||
            previous.seedArtist != current.seedArtist,
        builder: (context, state) => CustomScrollView(
          key: const PageStorageKey<String>('home-feed'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [homeFeedSliver(context, state, layout)],
        ),
      ),
    );
    return MaxContentWidth(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: showRecentlyPlayed ? 24.w : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: showRecentlyPlayed ? 70 : 100, child: feed),
            if (showRecentlyPlayed) ...[
              SizedBox(width: 24.w),
              Expanded(
                flex: 30,
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) =>
                      RecentlyPlayedPanel(tracks: state.continueListening),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
