import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/ui/song_tile.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/add_to_playlist_sheet.dart';

/// Offline downloads manager (PRD S14). Lists saved tracks with live
/// progress; completed rows play straight from the local file.

/// Downloads screen.
final class DownloadsPage extends StatelessWidget {
  /// Creates the downloads page.
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: MaxContentWidth(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: BlocBuilder<DownloadsCubit, DownloadsState>(
            builder: _buildBody,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DownloadsState state) {
    switch (state.status) {
      case DownloadsStatus.loading:
        return const StateView(
          kind: StateKind.loading,
          message: 'Loading downloads…',
        );
      case DownloadsStatus.empty:
        return const StateView(
          kind: StateKind.empty,
          message: 'No downloads yet.\nSave a track to listen offline.',
        );
      case DownloadsStatus.error:
        return StateView(
          kind: StateKind.error,
          message: state.error ?? 'Download failed',
        );
      case DownloadsStatus.ready:
        final downloads = state.downloads;
        final playable = downloads
            .where((d) => d.isComplete)
            .toList(growable: false);
        return ListView.separated(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: downloads.length,
          separatorBuilder: (_, _) => SizedBox(height: 8.w),
          itemBuilder: (context, index) {
            final download = downloads[index];
            return _DownloadRow(
              download: download,
              onPlay: download.isComplete
                  ? () => playFromCatalog(
                      context,
                      playable.map((d) => d.track).toList(growable: false),
                      playable.indexOf(download),
                    )
                  : null,
              onRemove: () =>
                  context.read<DownloadsCubit>().remove(download.track.id),
            );
          },
        );
    }
  }
}

final class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    required this.download,
    required this.onPlay,
    required this.onRemove,
  });

  final Download download;
  final VoidCallback? onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final track = download.track;
    return SongTile(
      title: track.title,
      subtitle: _subtitle(),
      artUrl: track.artUrl,
      onTap: onPlay,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusLeading(context),
          IconButton(
            tooltip: 'Add to playlist',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.playlist_add),
            onPressed: () => showAddToPlaylist(context, track),
          ),
          _actionButton(context),
          _deleteButton(context),
        ],
      ),
    );
  }

  String _subtitle() {
    final artist = download.track.artist;
    if (download.status == DownloadStatus.completed ||
        download.status == DownloadStatus.failed) {
      return artist;
    }
    if (download.totalBytes <= 0) return '$artist · Starting…';
    final percent = (download.progress * 100).round();
    return '$artist · $percent%';
  }

  Widget _actionButton(BuildContext context) {
    final cubit = context.read<DownloadsCubit>();
    final id = download.track.id;
    switch (download.status) {
      case DownloadStatus.completed:
        return const SizedBox.shrink();
      case DownloadStatus.downloading:
      case DownloadStatus.queued:
        return IconButton(
          icon: const Icon(Icons.pause_circle_outlined),
          tooltip: 'Pause download',
          onPressed: () => cubit.pause(id),
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_circle_outlined),
          tooltip: 'Resume download',
          onPressed: () => cubit.resume(id),
        );
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Retry download',
          onPressed: () => cubit.retry(id),
        );
    }
  }

  Widget _statusLeading(BuildContext context) {
    switch (download.status) {
      case DownloadStatus.completed:
        return Icon(Icons.download_done, size: 20.r);
      case DownloadStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 20.r,
          color: Theme.of(context).colorScheme.error,
        );
      case DownloadStatus.queued:
      case DownloadStatus.paused:
        return Icon(Icons.pause_circle_outline, size: 20.r);
      case DownloadStatus.downloading:
        return SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            value: download.totalBytes > 0 ? download.progress : null,
          ),
        );
    }
  }

  Widget _deleteButton(BuildContext context) => IconButton(
    icon: const Icon(Icons.delete_outline),
    tooltip: 'Remove download',
    onPressed: onRemove,
  );
}
