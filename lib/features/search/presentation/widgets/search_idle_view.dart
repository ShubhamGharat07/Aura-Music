import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/app_spinner.dart';
import 'package:aura_music/core/ui/glass_chip.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';
import 'package:aura_music/features/search/presentation/widgets/suggestion_tile.dart';

/// Idle search view (PRD S04): recent terms plus an API-backed ranked
/// "Suggestions" list. Nothing here is hard-coded.

/// Recent searches and ranked suggestions.
final class SearchIdleView extends StatelessWidget {
  /// Creates the idle view.
  const SearchIdleView({
    super.key,
    required this.recent,
    required this.onTermTap,
    required this.onClearRecent,
    required this.onRemoveTerm,
    required this.browse,
    required this.browseStatus,
    required this.browseError,
    required this.onPlay,
    required this.onRetry,
  });

  /// Recent terms (newest first).
  final List<String> recent;

  /// Tapping a recent term runs a search.
  final ValueChanged<String> onTermTap;

  /// Clears recent history.
  final VoidCallback onClearRecent;

  /// Forgets one recent term (chip ×).
  final ValueChanged<String> onRemoveTerm;

  /// Ranked suggestions (top songs by plays).
  final List<Track> browse;

  /// Load state of [browse].
  final BrowseStatus browseStatus;

  /// Error message when [browseStatus] is [BrowseStatus.error].
  final String? browseError;

  /// Plays [browse] from [index].
  final void Function(List<Track> tracks, int index) onPlay;

  /// Retries the suggestions fetch.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (recent.isNotEmpty) SliverToBoxAdapter(child: _recent()),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Suggestions')),
        ..._suggestions(),
        // Content scrolls under the floating chrome; reserve its measured
        // height (+ breathing room) so the last rows stay reachable.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.w),
        ),
      ],
    );
  }

  List<Widget> _suggestions() => switch (browseStatus) {
    BrowseStatus.loading => [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: const Center(child: AppSpinner()),
        ),
      ),
    ],
    BrowseStatus.error => [
      SliverToBoxAdapter(
        child: StateView(
          kind: StateKind.error,
          message: browseError ?? 'Could not load suggestions',
          onRetry: onRetry,
        ),
      ),
    ],
    BrowseStatus.ready when browse.isEmpty => [
      SliverToBoxAdapter(
        child: StateView(
          kind: StateKind.empty,
          message: 'Nothing trending right now',
        ),
      ),
    ],
    BrowseStatus.ready => [
      SliverList.builder(
        itemCount: browse.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(bottom: 8.w),
          child: SuggestionTile(
            rank: i + 1,
            track: browse[i],
            onTap: () => onPlay(browse, i),
          ),
        ),
      ),
    ],
  };

  Widget _recent() {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Recent', style: AppTypography.title)),
              TextButton(onPressed: onClearRecent, child: const Text('Clear')),
            ],
          ),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.w,
            children: [
              for (final term in recent)
                GlassChip(
                  label: term,
                  icon: Icons.history,
                  onTap: () => onTermTap(term),
                  onRemove: () => onRemoveTerm(term),
                ),
            ],
          ),
          SizedBox(height: 8.w),
        ],
      ),
    );
  }
}
