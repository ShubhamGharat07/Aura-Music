import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Live search terms displayed underneath the search field.
final class SearchSuggestionsView extends StatelessWidget {
  /// Creates the suggestions view.
  const SearchSuggestionsView({
    super.key,
    required this.suggestions,
    required this.onSelect,
    required this.onFill,
  });

  /// Catalog matches for the current query.
  final List<Track> suggestions;

  /// Submits a suggestion as a search.
  final ValueChanged<String> onSelect;

  /// Copies a suggestion into the search field for further editing.
  final ValueChanged<String> onFill;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SectionHeader(title: 'Suggestions')),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverList.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, i) {
              final title = suggestions[i].title;
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: GlassSurface.fake(
                  borderRadius: AppRadius.chip,
                  child: ListTile(
                    leading: Icon(
                      Icons.search_rounded,
                      size: 20.r,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Fill search with $title',
                      icon: Icon(
                        Icons.north_west_rounded,
                        size: 19.r,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => onFill(title),
                    ),
                    onTap: () => onSelect(title),
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
