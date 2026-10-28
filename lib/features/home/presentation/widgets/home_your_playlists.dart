import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/collection_card.dart';

/// "Your playlists" carousel (PRD S03). Local user playlists only; hidden
/// until the user creates one.

/// User-playlist section.
final class HomeYourPlaylists extends StatelessWidget {
  /// Creates the section.
  const HomeYourPlaylists({
    super.key,
    required this.padding,
    this.cardWidth = 160,
  });

  /// Horizontal inset from the window class.
  final double padding;

  /// Card width.
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        final playlists = state.playlists;
        if (playlists.isEmpty) return const SizedBox.shrink();
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
              child: SectionHeader(
                title: 'Your playlists',
                onSeeAll: () => context.push(AppRoutes.playlists),
              ),
            ),
            SizedBox(
              height: 238.w,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: padding),
                itemCount: playlists.length,
                separatorBuilder: (_, _) => SizedBox(width: 14.w),
                itemBuilder: (_, i) {
                  final playlist = playlists[i];
                  return SizedBox(
                    width: cardWidth,
                    child: CollectionCard(
                      title: playlist.name,
                      subtitle: playlist.songCount == 1
                          ? '1 song'
                          : '${playlist.songCount} songs',
                      artUrl: playlist.artUrl,
                      onTap: () =>
                          context.push('${AppRoutes.playlists}/${playlist.id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
