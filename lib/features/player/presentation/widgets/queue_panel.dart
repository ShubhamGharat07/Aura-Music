import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Queue (PRD S07 / F05): header (count, Clear, Shuffle), a pinned now-playing
/// tile and a reorderable "Up next" list (drag handle + swipe to remove).

/// Queue content.
final class QueuePanel extends StatelessWidget {
  /// Creates the queue panel.
  const QueuePanel({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.accent,
    this.onSelect,
    this.onReorder,
    this.onRemove,
    this.onClear,
    this.onShuffle,
  });

  /// Full queue.
  final List<Track> queue;

  /// Index of the currently playing track.
  final int currentIndex;

  /// Accent colour.
  final Color accent;

  /// Tapped an up-next row (full-queue index).
  final ValueChanged<int>? onSelect;

  /// Reordered up-next (full-queue indices, raw list semantics).
  final void Function(int oldIndex, int newIndex)? onReorder;

  /// Swiped away an up-next row (full-queue index).
  final ValueChanged<int>? onRemove;

  /// Clears the up-next queue.
  final VoidCallback? onClear;

  /// Shuffles the up-next queue.
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) {
    final current = currentIndex >= 0 && currentIndex < queue.length
        ? queue[currentIndex]
        : null;
    final offset = currentIndex + 1;
    final upNext = offset < queue.length
        ? queue.sublist(offset)
        : const <Track>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          count: queue.length,
          canMutate: upNext.isNotEmpty,
          canShuffle: upNext.length > 1,
          onClear: onClear,
          onShuffle: onShuffle,
        ),
        if (current != null) ...[
          SizedBox(height: 4.w),
          _NowPlayingTile(track: current, accent: accent),
        ],
        SizedBox(height: 12.w),
        Expanded(
          child: upNext.isEmpty
              ? StateView(kind: StateKind.empty, message: 'Nothing up next.')
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  itemCount: upNext.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      onReorder?.call(offset + oldIndex, offset + newIndex),
                  itemBuilder: (context, i) {
                    final track = upNext[i];
                    final index = offset + i;
                    return Padding(
                      key: ValueKey('queue-$index-${track.id}'),
                      padding: EdgeInsets.only(bottom: 8.w),
                      child: Dismissible(
                        key: ValueKey('queue-remove-$index-${track.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => onRemove?.call(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.remove_circle_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SongTile(
                                title: track.title,
                                subtitle: track.artist,
                                artUrl: track.artUrl,
                                onTap: onSelect == null
                                    ? null
                                    : () => onSelect!(index),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: i,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.canMutate,
    required this.canShuffle,
    this.onClear,
    this.onShuffle,
  });

  final int count;
  final bool canMutate;
  final bool canShuffle;
  final VoidCallback? onClear;
  final VoidCallback? onShuffle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            count == 1 ? '1 in queue' : '$count in queue',
            style: AppTypography.subtitle,
          ),
        ),
        IconButton(
          tooltip: 'Clear queue',
          onPressed: canMutate ? onClear : null,
          icon: const Icon(Icons.clear_all),
        ),
        IconButton(
          tooltip: 'Shuffle queue',
          onPressed: canShuffle ? onShuffle : null,
          icon: const Icon(Icons.shuffle),
        ),
      ],
    );
  }
}

final class _NowPlayingTile extends StatelessWidget {
  const _NowPlayingTile({required this.track, required this.accent});

  final Track track;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassSurface.fake(
      borderRadius: 16.r,
      child: ListTile(
        leading: Icon(Icons.equalizer_rounded, color: accent),
        title: Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.subtitle.copyWith(color: accent),
        ),
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption,
        ),
      ),
    );
  }
}
