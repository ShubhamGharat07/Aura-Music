import 'package:flutter/material.dart';

import 'package:aura_music/features/home/presentation/widgets/home_feed.dart';
import 'package:aura_music/features/home/presentation/widgets/home_feed_view.dart';

/// Compact home (PRD S03): quick picks 2 cols, 148 dp carousels, single
/// lazy scroll view with pull-to-refresh.

/// Compact home layout.
final class HomeCompactView extends StatelessWidget {
  /// Creates the compact view.
  const HomeCompactView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeFeedView(layout: HomeFeedLayout.compact());
  }
}
