import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/downloads/domain/entities/download_summary.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';

/// Library header + quick access rows (PRD S12).

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

/// Editorial library header: title, one metadata line, and the single create
/// action. The old gradient summary card and 2×2 shortcut tiles were doing the
/// same job four times; this says it once.
final class LibraryHeader extends StatelessWidget {
  /// Creates the header.
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedTracksCubit, LikedTracksState>(
      builder: (context, liked) {
        return BlocBuilder<PlaylistsCubit, PlaylistsState>(
          builder: (context, playlists) {
            return BlocBuilder<DownloadsCubit, DownloadsState>(
              builder: (context, downloads) {
                final summary = DownloadSummary.of(downloads.downloads);
                final parts = <String>[
                  if (liked.tracks.isNotEmpty) _songs(liked.tracks.length),
                  if (playlists.playlists.isNotEmpty)
                    _playlists(playlists.playlists.length),
                  if (summary.completed > 0) '${summary.completed} offline',
                ];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Library', style: AppTypography.display),
                          SizedBox(height: 6.w),
                          Text(
                            parts.isEmpty
                                ? 'Songs, playlists and downloads live here.'
                                : parts.join(' · '),
                            style: AppTypography.caption.copyWith(
                              fontSize: 13.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _NewPlaylistButton(
                      onTap: () => createLibraryPlaylist(context),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

String _songs(int count) => count == 1 ? '1 song' : '$count songs';

String _playlists(int count) => count == 1 ? '1 playlist' : '$count playlists';

/// Three quick access rows. Plain rows, not cards: this is a list of places to
/// go, and the icon + label already carry the hierarchy.
final class LibraryShortcuts extends StatelessWidget {
  /// Creates the quick access list.
  const LibraryShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikedTracksCubit, LikedTracksState>(
      builder: (context, liked) {
        final count = liked.tracks.length;
        return Column(
          children: [
            _AccessRow(
              icon: Icons.favorite_rounded,
              title: 'Liked songs',
              subtitle: count == 1 ? '1 song' : '$count songs',
              accent: true,
              onTap: () => context.push(AppRoutes.liked),
            ),
            const _RowDivider(),
            _AccessRow(
              icon: Icons.download_rounded,
              title: 'Downloads',
              subtitle: 'Available offline',
              onTap: () => context.push(AppRoutes.downloads),
            ),
            const _RowDivider(),
            _AccessRow(
              icon: Icons.history_rounded,
              title: 'History',
              subtitle: 'Recently played',
              onTap: () => context.push(AppRoutes.history),
            ),
          ],
        );
      },
    );
  }
}

final class _NewPlaylistButton extends HookWidget {
  const _NewPlaylistButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.92 : 1,
      duration: AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: AppColors.textPrimary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onHighlightChanged: (value) => pressed.value = value,
          child: SizedBox(
            width: 38.w,
            height: 38.w,
            child: AnimatedRotation(
              turns: pressed.value && !reduceMotion ? 0.125 : 0,
              duration: AppDurations.fast,
              curve: AppCurves.out,
              child: Icon(Icons.add_rounded, size: 21.r, color: AppColors.bg),
            ),
          ),
        ),
      ),
    );
  }
}

final class _AccessRow extends HookWidget {
  const _AccessRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onHighlightChanged: (value) => pressed.value = value,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.out,
          color: pressed.value
              ? AppColors.textPrimary.withValues(alpha: 0.035)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 11.w, horizontal: 4.w),
          child: Row(
            children: [
              SizedBox(
                width: 24.w,
                child: Icon(
                  icon,
                  size: 21.r,
                  color: accent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.w),
                    Text(
                      subtitle,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18.r,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 39.w),
      child: const Divider(
        height: 1,
        thickness: 0.6,
        color: AppColors.glassBorder,
      ),
    );
  }
}
