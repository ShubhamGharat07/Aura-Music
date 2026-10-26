import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_sheet.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// "Add to playlist" sheet (PRD overlay O2).

/// Opens the add-to-playlist sheet for [track].
Future<void> showAddToPlaylist(BuildContext context, Track track) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final target = await GlassSheet.show<String>(
    context,
    (_) => BlocProvider<PlaylistsCubit>(
      create: (_) => getIt<PlaylistsCubit>()..load(),
      child: _AddToPlaylistSheet(track: track),
    ),
  );
  if (target != null) {
    messenger?.showSnackBar(SnackBar(content: Text('Added to $target')));
  }
}

final class _AddToPlaylistSheet extends StatelessWidget {
  const _AddToPlaylistSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return BlocBuilder<PlaylistsCubit, PlaylistsState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add to playlist', style: AppTypography.title),
            SizedBox(height: 2.w),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
            SizedBox(height: 8.w),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('New playlist'),
              onTap: () => _createAndAdd(context),
            ),
            Divider(height: 1),
            if (state.status == PlaylistsStatus.loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 32.w),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (state.playlists.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.w),
                child: Text(
                  'No playlists yet. Create one to save this song.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height * 0.42),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 4.w),
                  itemCount: state.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.queue_music),
                      title: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        playlist.songCount == 1
                            ? '1 song'
                            : '${playlist.songCount} songs',
                        style: AppTypography.caption,
                      ),
                      onTap: () => _add(context, playlist.id, playlist.name),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
    final cubit = context.read<PlaylistsCubit>();
    final name = await promptForText(
      context,
      title: 'New playlist',
      confirmLabel: 'Create',
      hint: 'Playlist name',
    );
    if (name == null || name.trim().isEmpty) return;
    final playlistName = name.trim();
    final id = await cubit.create(playlistName);
    if (!context.mounted) return;
    await _add(context, id, playlistName);
  }

  Future<void> _add(
    BuildContext context,
    String playlistId,
    String playlistName,
  ) async {
    final cubit = context.read<PlaylistsCubit>();
    try {
      await cubit.addTrack(playlistId, track);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('Could not add this song')));
      return;
    }
    if (context.mounted) Navigator.pop(context, playlistName);
  }
}
