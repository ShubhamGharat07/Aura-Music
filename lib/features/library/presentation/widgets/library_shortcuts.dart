import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/features/downloads/domain/entities/download_summary.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';

/// Library overview + shortcut tiles (PRD S12).

/// Prompts for a name, creates a playlist and opens it.
Future<void> createLibraryPlaylist(BuildContext context) async {
  final cubit = context.read<PlaylistsCubit>();
  final name = await promptForText(
    context,
    title: 'New playlist',
    confirmLabel: 'Create',
    hint: 'Playlist name',
  );
  if (name == null || name.trim().isEmpty) return;
  final id = await cubit.create(name.trim());
  if (!context.mounted) return;
  context.push('${AppRoutes.playlists}/$id');
}

/// Compact summary of what lives in the user's library.
final class LibraryOverview extends StatelessWidget {
  /// Creates the overview card.
  const LibraryOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return BlocBuilder<LikedTracksCubit, LikedTracksState>(
      builder: (context, liked) {
        return BlocBuilder<PlaylistsCubit, PlaylistsState>(
          builder: (context, playlists) {
            return BlocBuilder<DownloadsCubit, DownloadsState>(
              builder: (context, downloads) {
                final summary = DownloadSummary.of(downloads.downloads);
                return GlassSurface.fake(
                  borderRadius: AppRadius.card,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.20),
                          AppColors.glassFill,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your music', style: AppTypography.title),
                          SizedBox(height: 2.w),
                          Text(
                            'Everything stays on this device.',
                            style: AppTypography.caption,
                          ),
                          SizedBox(height: 14.w),
                          Row(
                            children: [
                              _Stat(
                                value: '${liked.tracks.length}',
                                label: 'Liked',
                              ),
                              _Divider(),
                              _Stat(
                                value: '${playlists.playlists.length}',
                                label: 'Playlists',
                              ),
                              _Divider(),
                              _Stat(
                                value: '${summary.completed}',
                                label: 'Offline',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title.copyWith(fontSize: 21.sp),
          ),
          SizedBox(height: 2.w),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

final class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30.w,
      margin: EdgeInsets.only(right: 14.w),
      color: AppColors.glassBorder,
    );
  }
}

/// Four shortcut tiles. 2A-2 on compact, a row on medium+.
final class LibraryShortcuts extends StatelessWidget {
  /// Creates the shortcuts section.
  const LibraryShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedTracksCubit, LikedTracksState>(
      builder: (context, liked) {
        final count = liked.tracks.length;
        final tiles = [
          (
            title: 'Liked',
            subtitle: count == 1 ? '1 song' : '$count songs',
            icon: Icons.favorite_outline_rounded,
            onTap: () => context.push(AppRoutes.liked),
          ),
          (
            title: 'Downloads',
            subtitle: 'Offline',
            icon: Icons.download_outlined,
            onTap: () => context.push(AppRoutes.downloads),
          ),
          (
            title: 'History',
            subtitle: 'Recently played',
            icon: Icons.history_rounded,
            onTap: () => context.push(AppRoutes.history),
          ),
          (
            title: 'New playlist',
            subtitle: 'Create',
            icon: Icons.playlist_add_rounded,
            onTap: () => createLibraryPlaylist(context),
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 840) {
              return Row(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) SizedBox(width: 12.w),
                    Expanded(
                      child: _Tile(
                        title: tiles[i].title,
                        subtitle: tiles[i].subtitle,
                        icon: tiles[i].icon,
                        onTap: tiles[i].onTap,
                      ),
                    ),
                  ],
                ],
              );
            }
            final rows = <Widget>[];
            for (var i = 0; i < tiles.length; i += 2) {
              if (i > 0) rows.add(SizedBox(height: 12.w));
              rows.add(
                Row(
                  children: [
                    Expanded(
                      child: _Tile(
                        title: tiles[i].title,
                        subtitle: tiles[i].subtitle,
                        icon: tiles[i].icon,
                        onTap: tiles[i].onTap,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _Tile(
                        title: tiles[i + 1].title,
                        subtitle: tiles[i + 1].subtitle,
                        icon: tiles[i + 1].icon,
                        onTap: tiles[i + 1].onTap,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(children: rows);
          },
        );
      },
    );
  }
}

final class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GlassSurface.fake(
      borderRadius: AppRadius.card,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 11.w, 10.w, 11.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Icon(icon, size: 19.r, color: accent),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.r,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                SizedBox(height: 9.w),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
