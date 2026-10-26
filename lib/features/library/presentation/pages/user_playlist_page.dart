import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/library/domain/entities/user_playlist_detail.dart';
import 'package:aura_music/features/library/presentation/bloc/user_playlist_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// A user playlist (PRD S13): play/shuffle, rename, delete, remove tracks.

/// User playlist detail screen.
final class UserPlaylistPage extends StatelessWidget {
  /// Creates the user playlist page.
  const UserPlaylistPage({super.key, required this.playlistId});

  /// Playlist id to load.
  final String playlistId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserPlaylistCubit>(
      create: (_) => getIt<UserPlaylistCubit>()..load(playlistId),
      child: const _UserPlaylistView(),
    );
  }
}

final class _UserPlaylistView extends StatelessWidget {
  const _UserPlaylistView();

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final cubit = context.read<UserPlaylistCubit>();
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<UserPlaylistCubit, UserPlaylistState>(
          builder: (context, state) =>
              Text(state.detail?.playlist.name ?? 'Playlist'),
        ),
        actions: [
          BlocBuilder<UserPlaylistCubit, UserPlaylistState>(
            builder: (context, state) =>
                state.status == UserPlaylistStatus.ready
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rename',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () =>
                            _rename(context, state.detail!.playlist.name),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: MaxContentWidth(
        child: BlocBuilder<UserPlaylistCubit, UserPlaylistState>(
          builder: (context, state) {
            switch (state.status) {
              case UserPlaylistStatus.loading:
                return const StateView(
                  kind: StateKind.loading,
                  message: 'Loading…',
                );
              case UserPlaylistStatus.error:
                return StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Could not load',
                  onRetry: () => cubit.load(state.id),
                );
              case UserPlaylistStatus.missing:
                return const StateView(
                  kind: StateKind.empty,
                  message: 'This playlist no longer exists.',
                );
              case UserPlaylistStatus.ready:
                break;
            }
            return _Body(detail: state.detail!, pad: pad);
          },
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, String current) async {
    final cubit = context.read<UserPlaylistCubit>();
    final name = await promptForText(
      context,
      title: 'Rename playlist',
      confirmLabel: 'Save',
      initial: current,
    );
    if (name == null || name.trim().isEmpty) return;
    await cubit.rename(name.trim());
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<UserPlaylistCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete playlist?'),
        content: const Text('This removes the playlist and its songs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    await cubit.delete();
    if (context.mounted) context.pop();
  }
}

final class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.pad});

  final UserPlaylistDetail detail;
  final double pad;

  @override
  Widget build(BuildContext context) {
    final songs = detail.songs;
    final count = songs.length;
    final cubit = context.read<UserPlaylistCubit>();
    final children = <Widget>[
      Text(detail.playlist.name, style: AppTypography.display),
      SizedBox(height: 4.w),
      Text(
        count == 1 ? '1 song' : '$count songs',
        style: AppTypography.caption,
      ),
      SizedBox(height: 12.w),
      Wrap(
        spacing: 8.w,
        runSpacing: 8.w,
        children: [
          FilledButton.icon(
            onPressed: count == 0
                ? null
                : () => playFromCatalog(context, songs, 0),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
          OutlinedButton.icon(
            onPressed: count == 0 ? null : () => _shuffle(context, songs),
            icon: const Icon(Icons.shuffle),
            label: const Text('Shuffle'),
          ),
        ],
      ),
      SizedBox(height: 12.w),
      if (count == 0)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40.w),
          child: StateView(
            kind: StateKind.empty,
            message: 'No songs yet. Add some from a track.',
          ),
        )
      else
        for (var i = 0; i < songs.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 8.w),
            child: SongTile(
              title: songs[i].title,
              subtitle: songs[i].subtitle,
              artUrl: songs[i].artUrl,
              track: songs[i],
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => cubit.removeTrack(songs[i].id),
              ),
              onTap: () => playFromCatalog(context, songs, i),
            ),
          ),
    ];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        pad,
        16.w,
        pad,
        pad + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  void _shuffle(BuildContext context, List<Track> songs) {
    playFromCatalog(context, songs, Random().nextInt(songs.length));
  }
}
