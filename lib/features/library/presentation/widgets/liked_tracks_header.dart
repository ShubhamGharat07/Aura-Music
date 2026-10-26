import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';

/// Liked-songs header: count + Play / Shuffle / sort (PRD S14).

/// Liked-songs action header.
final class LikedTracksHeader extends StatelessWidget {
  /// Creates the header.
  const LikedTracksHeader({
    super.key,
    required this.count,
    required this.sort,
    required this.onPlay,
    required this.onShuffle,
    required this.onCycleSort,
  });

  /// Number of liked songs.
  final int count;

  /// Active sort order.
  final LikedSort sort;

  /// Play all (current order).
  final VoidCallback onPlay;

  /// Start shuffled.
  final VoidCallback onShuffle;

  /// Advance the sort order.
  final VoidCallback onCycleSort;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count == 1 ? '1 song' : '$count songs',
          style: AppTypography.caption,
        ),
        SizedBox(height: 12.w),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.w,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            OutlinedButton.icon(
              onPressed: onShuffle,
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle'),
            ),
            TextButton.icon(
              onPressed: onCycleSort,
              icon: const Icon(Icons.sort),
              label: Text(_sortLabel(sort)),
            ),
          ],
        ),
      ],
    );
  }

  String _sortLabel(LikedSort sort) => switch (sort) {
    LikedSort.recent => 'Recent',
    LikedSort.title => 'Title',
    LikedSort.artist => 'Artist',
  };
}
