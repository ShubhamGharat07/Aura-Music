import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/ui/glass_chip.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';

/// Horizontal filter chips for the result groups (PRD S05).

/// All / Songs / Albums / Artists / Playlists chips with match counts.
final class SearchFilterBar extends StatelessWidget {
  /// Creates the filter bar.
  const SearchFilterBar({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onSelect,
  });

  /// Active filter.
  final SearchFilter selected;

  /// Match count for a filter (badge).
  final int Function(SearchFilter) countFor;

  /// Fired when a chip is tapped.
  final ValueChanged<SearchFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.w,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SearchFilter.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final filter = SearchFilter.values[i];
          final count = countFor(filter);
          return GlassChip(
            label: count > 0 ? '${filter.label} · $count' : filter.label,
            selected: filter == selected,
            onTap: () => onSelect(filter),
          );
        },
      ),
    );
  }
}
