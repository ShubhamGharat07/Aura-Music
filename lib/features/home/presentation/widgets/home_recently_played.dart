import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// "Recently played" right column (PRD S03, Expanded/Large only).

/// A fixed-width list of the tracks the user played last.
final class RecentlyPlayedPanel extends StatelessWidget {
  /// Creates the panel.
  const RecentlyPlayedPanel({super.key, required this.tracks});

  /// Recently played tracks (newest first).
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tracks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const SectionHeader(title: 'Recently played');
        final track = tracks[index - 1];
        return Padding(
          padding: EdgeInsets.only(top: 8.w),
          child: SongTile(
            title: track.title,
            subtitle: track.artist,
            artUrl: track.artUrl,
            track: track,
            onTap: () => playFromCatalog(context, tracks, index - 1),
          ),
        );
      },
    );
  }
}
