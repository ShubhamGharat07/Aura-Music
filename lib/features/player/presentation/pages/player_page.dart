import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/app_dialog.dart';
import 'package:aura_music/core/router/player_route.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/ui/glass_sheet.dart';
import 'package:aura_music/core/utils/color_from_id.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';
import 'package:aura_music/features/party/presentation/bloc/party_bloc.dart';
import 'package:aura_music/features/party/presentation/widgets/party_popover.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';
import 'package:aura_music/features/player/presentation/widgets/player_background.dart';
import 'package:aura_music/features/player/presentation/widgets/player_common_widgets.dart';
import 'package:aura_music/features/player/presentation/widgets/player_expanded_layout.dart';
import 'package:aura_music/features/player/presentation/widgets/player_landscape_layout.dart';
import 'package:aura_music/features/player/presentation/widgets/player_side_panel.dart';
import 'package:aura_music/features/player/presentation/widgets/player_vertical_layout.dart';

// Now Playing (PRD S06). Thin holder provides the global PlayerBloc;
// [_PlayerView] reads the window class and delegates to a per-class layout.

/// Now Playing route root.
final class PlayerPage extends StatelessWidget {
  /// Creates the player page.
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlayerBloc>.value(
      value: getIt<PlayerBloc>(),
      child: BlocProvider<LyricsCubit>(
        create: (_) => getIt<LyricsCubit>(),
        child: BlocProvider<PartyBloc>.value(
          value: getIt<PartyBloc>(),
          child: const _PlayerView(),
        ),
      ),
    );
  }
}

final class _PlayerView extends HookWidget {
  const _PlayerView();

  @override
  Widget build(BuildContext context) {
    final showPanel = useState(true);
    final panelTab = useState(0);
    final state = context.watch<PlayerBloc>().state;
    final bloc = context.read<PlayerBloc>();
    final track = state.currentTrack;
    final accent = track == null
        ? Theme.of(context).colorScheme.primary
        : accentFromId(track.id);
    final sizeClass = WindowSizeClass.of(context);
    final shortHeight = WindowSizeClass.isCompactHeight(context);
    final lyricsCubit = context.read<LyricsCubit>();
    final partyActive = context.watch<PartyBloc>().state.session.isActive;
    useEffect(() {
      if (track != null) lyricsCubit.load(track);
      return null;
    }, [track?.id]);
    void openPanel(int tab) {
      panelTab.value = tab;
      if (sizeClass.isExpandedUp && !shortHeight) {
        showPanel.value = true;
        return;
      }
      _openPanel(context, bloc, accent, tab);
    }

    void download() => _download(context, track!);
    void party(BuildContext anchor) => showPartyPopover(anchor);

    final Widget body;
    if (track == null) {
      body = const PlayerEmptyState();
    } else if (sizeClass.isExpandedUp && !shortHeight) {
      body = PlayerExpandedLayout(
        bloc: bloc,
        state: state,
        accent: accent,
        showPanel: showPanel.value,
        panelTab: panelTab.value,
        onCollapse: () => closePlayer(context),
        onMore: () => _showMenu(context, bloc, track),
        onTogglePanel: () => showPanel.value = !showPanel.value,
        onLyrics: () => openPanel(0),
        onQueue: () => openPanel(1),
        onTabSelected: (tab) => panelTab.value = tab,
        onDownload: download,
        onParty: party,
        partyActive: partyActive,
      );
    } else if (shortHeight) {
      body = PlayerLandscapeLayout(
        bloc: bloc,
        state: state,
        accent: accent,
        onCollapse: () => closePlayer(context),
        onMore: () => _showMenu(context, bloc, track),
        onLyrics: () => openPanel(0),
        onQueue: () => openPanel(1),
        onDownload: download,
      );
    } else {
      body = PlayerVerticalLayout(
        bloc: bloc,
        state: state,
        accent: accent,
        onCollapse: () => closePlayer(context),
        onMore: () => _showMenu(context, bloc, track),
        onLyrics: () => openPanel(0),
        onQueue: () => openPanel(1),
        onDownload: download,
        onParty: party,
        partyActive: partyActive,
      );
    }

    return BlocListener<PlayerBloc, PlayerState>(
      listenWhen: (previous, current) =>
          current.status == PlaybackStatus.error &&
          previous.error != current.error,
      listener: (context, current) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(current.error ?? 'Could not play this track'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => bloc.add(const PlayerPlayPauseToggled()),
            ),
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const PlayerBackground(),
            SafeArea(child: body),
          ],
        ),
      ),
    );
  }

  void _openPanel(
    BuildContext context,
    PlayerBloc bloc,
    Color accent,
    int initialTab,
  ) {
    final lyricsCubit = context.read<LyricsCubit>();
    GlassSheet.show(
      context,
      (sheetContext) => BlocProvider<LyricsCubit>.value(
        value: lyricsCubit,
        child: SizedBox(
          // Clamp to the viewport so the panel still fits in phone landscape.
          height: (MediaQuery.sizeOf(sheetContext).height * 0.78)
              .clamp(260.0, 460.w)
              .toDouble(),
          child: BlocBuilder<PlayerBloc, PlayerState>(
            bloc: bloc,
            builder: (context, live) => PlayerSidePanel(
              accent: accent,
              state: live,
              position: bloc.controller.position,
              initialTab: initialTab,
              onSelectQueue: (i) {
                // Give the new track the full screen instead of leaving a
                // sheet that still describes the old queue position.
                closeOverlay(sheetContext);
                bloc.add(PlayerQueueSelected(i));
              },
              onReorderQueue: (o, n) => bloc.add(PlayerQueueReordered(o, n)),
              onRemoveQueue: (i) => bloc.add(PlayerQueueItemRemoved(i)),
              onClearQueue: () => bloc.add(const PlayerQueueCleared()),
              onShuffleQueue: () => bloc.add(const PlayerQueueShuffled()),
              onClose: () => closeOverlay(sheetContext),
            ),
          ),
        ),
      ),
    );
  }

  void _download(BuildContext context, Track track) {
    final messenger = ScaffoldMessenger.of(context);
    var complete = false;
    var active = false;
    for (final download in context.read<DownloadsCubit>().state.downloads) {
      if (download.track.id != track.id) continue;
      complete = download.isComplete;
      active = download.isActive;
    }
    if (complete) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Already available offline')),
      );
      return;
    }
    if (active) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Already downloading')),
      );
      return;
    }
    context.read<DownloadsCubit>().download(track);
    messenger.showSnackBar(
      SnackBar(content: Text('Downloading “${track.title}”')),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    PlayerBloc bloc,
    Track track,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final liked = bloc.state.isLiked(track.id);
    final action = await GlassSheet.show<String>(
      context,
      (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: const Text('Play next'),
            onTap: () {
              closeOverlay(sheetContext);
              bloc.add(PlayerQueueTrackPlayNext(track));
              messenger.showSnackBar(
                const SnackBar(content: Text('Playing next')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to queue'),
            onTap: () {
              closeOverlay(sheetContext);
              bloc.add(PlayerQueueTrackAppended(track));
              messenger.showSnackBar(
                SnackBar(content: Text('Added “${track.title}” to the queue')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () => Navigator.pop(sheetContext, 'playlist'),
          ),
          ListTile(
            leading: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            ),
            title: Text(liked ? 'Remove from liked' : 'Add to liked'),
            onTap: () {
              closeOverlay(sheetContext);
              bloc.add(PlayerLikeToggled(track.id));
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download'),
            onTap: () {
              closeOverlay(sheetContext);
              _download(context, track);
            },
          ),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
    if (action == 'playlist' && context.mounted) {
      await showAddToPlaylist(context, track);
    }
  }
}
