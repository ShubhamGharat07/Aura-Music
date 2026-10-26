import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/collection_card.dart';
import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';

/// User playlists (PRD S12): grid of local playlists + create.

/// Playlists screen.
final class PlaylistsPage extends StatelessWidget {
  /// Creates the playlists page.
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlaylistsCubit>(
      create: (_) => getIt<PlaylistsCubit>()..load(),
      child: const _PlaylistsView(),
    );
  }
}

final class _PlaylistsView extends StatelessWidget {
  const _PlaylistsView();

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final cubit = context.read<PlaylistsCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('New playlist'),
      ),
      body: MaxContentWidth(
        child: BlocBuilder<PlaylistsCubit, PlaylistsState>(
          builder: (context, state) {
            switch (state.status) {
              case PlaylistsStatus.loading:
                return const StateView(
                  kind: StateKind.loading,
                  message: 'Loading…',
                );
              case PlaylistsStatus.error:
                return StateView(
                  kind: StateKind.error,
                  message: state.error ?? 'Could not load',
                  onRetry: cubit.load,
                );
              case PlaylistsStatus.empty:
                return const StateView(
                  kind: StateKind.empty,
                  message: 'Create your first playlist.',
                );
              case PlaylistsStatus.ready:
                break;
            }
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(
                pad,
                8.w,
                pad,
                96.w + MediaQuery.paddingOf(context).bottom,
              ),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12.w,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.82,
              ),
              itemCount: state.playlists.length,
              itemBuilder: (context, index) {
                final playlist = state.playlists[index];
                return CollectionCard(
                  title: playlist.name,
                  subtitle: playlist.songCount == 1
                      ? '1 song'
                      : '${playlist.songCount} songs',
                  artUrl: playlist.artUrl,
                  onTap: () =>
                      context.push('${AppRoutes.playlists}/${playlist.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
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
}
