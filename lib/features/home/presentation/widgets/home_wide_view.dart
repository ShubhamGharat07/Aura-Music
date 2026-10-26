import 'package:flutter/material.dart';

import 'package:aura_music/features/home/presentation/widgets/home_feed.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed_view.dart';

/// Wide home (PRD S03): quick picks 4 cols, arrow carousels, max content
/// width 1200 and an optional "Recently played" right column on Large.

/// Medium / Expanded / Large home layout.
final class HomeWideView extends StatelessWidget {
  /// Creates the wide view.
  const HomeWideView({super.key, this.showRecentlyPlayed = false});

  /// Show the Recently-played column (Large only).
  final bool showRecentlyPlayed;

  @override
  Widget build(BuildContext context) {
    return HomeFeedView(
      layout: const HomeFeedLayout.wide(),
      showRecentlyPlayed: showRecentlyPlayed,
    );
  }
}
