import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_chip.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';

/// Language browse row (PRD S03), shown at the end of the home feed.
///
/// The catalog filters by language but ships no endpoint that lists them, so
/// the chips are the declared [kCatalogLanguages]; the songs behind a chip are
/// fetched from the catalog when it is opened.

/// Languages chips row.
final class HomeLanguages extends StatelessWidget {
  /// Creates the languages row.
  const HomeLanguages({
    super.key,
    required this.padding,
    required this.languages,
    required this.selected,
    required this.onSelect,
  });

  /// Horizontal inset from the window class.
  final double padding;

  /// Languages offered as chips.
  final List<CatalogLanguage> languages;

  /// Currently open language (null = collapsed).
  final CatalogLanguage? selected;

  /// Fired with the tapped language (null collapses the section).
  final ValueChanged<CatalogLanguage?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.lg,
            padding,
            AppSpacing.xs,
          ),
          child: const SectionHeader(title: 'Languages'),
        ),
        SizedBox(
          height: 44.r,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: languages.length,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (_, i) => GlassChip(
              label: languages[i].name,
              selected: languages[i].code == selected?.code,
              onTap: () => onSelect(languages[i]),
            ),
          ),
        ),
      ],
    );
  }
}
