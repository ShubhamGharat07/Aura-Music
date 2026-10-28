import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_chip.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';

/// Moods & genres chips (PRD S03), fed by the catalog's own browse channels.

/// Label of the chip that clears the mood filter.
const String kHomeMoodsAllLabel = 'All';

/// Moods row; tapping a chip filters the home feed by that mood / genre.
final class HomeMoods extends StatelessWidget {
  /// Creates the moods row.
  const HomeMoods({
    super.key,
    required this.padding,
    required this.genres,
    required this.selected,
    required this.onSelect,
  });

  /// Horizontal inset from the window class.
  final double padding;

  /// Browse channels from the catalog (empty until the row loads / fails).
  final List<Genre> genres;

  /// Currently selected channel (null = "All").
  final Genre? selected;

  /// Fired with the tapped channel; null for the "All" chip.
  final ValueChanged<Genre?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        height: 43.r,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padding),
          itemCount: genres.length + 1,
          separatorBuilder: (_, _) => SizedBox(width: 9.w),
          itemBuilder: (_, i) =>
              i == 0 ? _allChip() : _genreChip(genres[i - 1]),
        ),
      ),
    );
  }

  Widget _allChip() => GlassChip(
    label: kHomeMoodsAllLabel,
    selected: selected == null,
    onTap: () => onSelect(null),
  );

  Widget _genreChip(Genre genre) => GlassChip(
    label: genre.name,
    selected: genre.id == selected?.id,
    onTap: () => onSelect(genre),
  );
}
