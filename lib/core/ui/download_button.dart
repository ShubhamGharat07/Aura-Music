import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/downloads/domain/entities/download.dart';
import 'package:aura_music/features/downloads/presentation/bloc/downloads_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Inline download toggle shown on track rows (PRD S14). Reflects live
/// [DownloadsCubit] state: outline → in-progress → done (tap to remove).

/// Track download button.
final class DownloadButton extends StatelessWidget {
  /// Creates the button.
  const DownloadButton({super.key, required this.track, this.accent});

  /// Track to download.
  final Track track;

  /// Accent colour shown when the track is downloaded.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsCubit, DownloadsState>(
      builder: (context, state) {
        Download? match;
        for (final download in state.downloads) {
          if (download.track.id == track.id) {
            match = download;
            break;
          }
        }
        final status = match?.status;
        final busy =
            status == DownloadStatus.downloading ||
            status == DownloadStatus.queued ||
            status == DownloadStatus.paused;
        final done = status == DownloadStatus.completed;
        return IconButton(
          tooltip: done ? 'Remove download' : 'Download',
          color: done ? accent : null,
          icon: Icon(switch (status) {
            DownloadStatus.completed => Icons.download_done_rounded,
            DownloadStatus.downloading ||
            DownloadStatus.queued ||
            DownloadStatus.paused => Icons.downloading_rounded,
            _ => Icons.download_outlined,
          }),
          onPressed: busy ? null : () => _toggle(context, done),
        );
      },
    );
  }

  void _toggle(BuildContext context, bool done) {
    final cubit = context.read<DownloadsCubit>();
    if (done) {
      cubit.remove(track.id);
    } else {
      cubit.download(track);
    }
  }
}
