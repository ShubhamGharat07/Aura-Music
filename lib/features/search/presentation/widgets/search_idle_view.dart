import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/app_spinner.dart';
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
        itemBuilder: (context, i) => SuggestionTile(
          rank: i + 1,
          track: browse[i],
          onTap: () => onPlay(browse, i),
        ),
      ),
    ],
  };

  Widget _recent() {
    final terms = recent.take(6).toList(growable: false);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Recent searches', style: AppTypography.title),
              ),
              TextButton(
                onPressed: onClearRecent,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 36.w),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTypography.caption.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          for (final term in terms)
            _RecentRow(
              term: term,
              onTap: () => onTermTap(term),
              onRemove: () => onRemoveTerm(term),
            ),
          SizedBox(height: 4.w),
        ],
      ),
    );
  }
}

// One recent term: history glyph, single-line label that ellipsizes inside the
// row, and a remove action pinned to the trailing edge so long terms can never
// push the × off-screen.
final class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18.r,
                color: AppColors.textTertiary,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  term,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 15.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              InkResponse(
                onTap: onRemove,
                radius: 20.r,
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.r,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
