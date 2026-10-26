import 'package:flutter/material.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';

/// Type-ahead suggestion list (PRD S04).

/// Suggestion rows; tapping one submits its title as the query.
final class SearchSuggestionsView extends StatelessWidget {
  /// Creates the suggestions view.
  const SearchSuggestionsView({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  /// Suggestion tracks.
  final List<Track> suggestions;

  /// Called with the chosen suggestion's title.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      itemCount: suggestions.length,
      itemBuilder: (context, i) {
        final track = suggestions[i];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onSelect(track.title),
        );
      },
    );
  }
}
