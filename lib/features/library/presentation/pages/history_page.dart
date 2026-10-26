import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/library/presentation/bloc/history_cubit.dart';

/// Play history (PRD S15): grouped by day, clear-all.

/// History screen.
final class HistoryPage extends StatelessWidget {
  /// Creates the history page.
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => getIt<HistoryCubit>()..load(),
      child: const _HistoryView(),
    );
  }
}

final class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final cubit = context.read<HistoryCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) => state.entries.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear history',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: MaxContentWidth(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            switch (state.status) {
              case HistoryStatus.loading:
                return const StateView(
                  kind: StateKind.loading,
                  message: 'Loading…',
                );
              case HistoryStatus.error:
                return StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Could not load',
                  onRetry: cubit.load,
                );
              case HistoryStatus.empty:
                return const StateView(
                  kind: StateKind.empty,
                  message: 'Songs you play will show up here.',
                );
              case HistoryStatus.ready:
                break;
            }
            final groups = state.groups;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                pad,
                8.w,
                pad,
                pad + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) => _DayGroup(group: groups[index]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final cubit = context.read<HistoryCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all plays from your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await cubit.clear();
  }
}

final class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.group});

  final HistoryGroup group;

  @override
  Widget build(BuildContext context) {
    final tracks = group.entries
        .map((entry) => entry.track)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.w, bottom: 8.w),
          child: Text(_label(group.day), style: AppTypography.title),
        ),
        for (var i = 0; i < group.entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: SongTile(
              title: group.entries[i].track.title,
              subtitle: group.entries[i].track.subtitle,
              artUrl: group.entries[i].track.artUrl,
              track: group.entries[i].track,
              trailing: Text(
                DateFormat.jm().format(group.entries[i].playedAt.toLocal()),
                style: AppTypography.caption,
              ),
              onTap: () => playFromCatalog(context, tracks, i),
            ),
          ),
      ],
    );
  }

  String _label(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat.yMMMMd().format(day);
  }
}
