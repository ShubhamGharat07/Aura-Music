import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/lyrics/domain/entities/lyrics.dart';
import 'package:aura_music/features/lyrics/presentation/bloc/lyrics_cubit.dart';

// Synced lyrics panel (F11). LRCLIB lyrics via [LyricsCubit]; the active line
// is emphasised by colour/weight (never Opacity) as position advances.

/// Lyrics tab content.
final class LyricsPanel extends StatelessWidget {
  /// Creates the lyrics panel.
  const LyricsPanel({
    super.key,
    required this.state,
    required this.position,
    required this.accent,
    this.fontScale = 1,
  });

  /// Lyrics state (status + lines).
  final LyricsState state;

  /// Playback position (high frequency).
  final ValueListenable<Duration> position;

  /// Accent colour for the active line.
  final Color accent;

  /// Extra font step (tablets scale one step larger).
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case LyricsStatus.idle:
      case LyricsStatus.loading:
        return const StateView(
          kind: StateKind.loading,
          message: 'Loading lyrics…',
        );
      case LyricsStatus.empty:
        return const StateView(
          kind: StateKind.empty,
          message: 'No lyrics available',
        );
      case LyricsStatus.error:
        return StateView(
          kind: StateKind.error,
          message: state.error ?? 'Could not load lyrics',
        );
      case LyricsStatus.ready:
        return _SyncedLyrics(
          lyrics: state.lyrics!,
          position: position,
          accent: accent,
          fontScale: fontScale,
        );
    }
  }
}

final class _SyncedLyrics extends StatelessWidget {
  const _SyncedLyrics({
    required this.lyrics,
    required this.position,
    required this.accent,
    required this.fontScale,
  });

  final Lyrics lyrics;
  final ValueListenable<Duration> position;
  final Color accent;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    if (!lyrics.synced) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 8.w),
        itemCount: lyrics.lines.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.symmetric(vertical: 8.w),
          child: Text(
            lyrics.lines[i].text,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontSize: 17.sp * fontScale),
          ),
        ),
      );
    }
    return _ActiveLyrics(
      lyrics: lyrics,
      position: position,
      accent: accent,
      fontScale: fontScale,
    );
  }
}

/// Rebuilds the lyric list only when the active *line* changes.
///
/// Position ticks at >=10 Hz; mapping each tick to a widget rebuild re-lays out
/// the whole list several times a second. A [ValueNotifier<int>] that only
/// changes on line transitions keeps the panel quiet between lines.
final class _ActiveLyrics extends HookWidget {
  const _ActiveLyrics({
    required this.lyrics,
    required this.position,
    required this.accent,
    required this.fontScale,
  });

  final Lyrics lyrics;
  final ValueListenable<Duration> position;
  final Color accent;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final active = useMemoized(() => _ActiveIndexNotifier(position, lyrics), [
      position,
      lyrics,
    ]);
    useEffect(() => active.dispose, [active]);

    return ValueListenableBuilder<int?>(
      valueListenable: active,
      builder: (context, activeIndex, _) => ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 8.w),
        itemCount: lyrics.lines.length,
        itemBuilder: (context, i) {
          final isActive = i == activeIndex;
          final style = (isActive ? AppTypography.title : AppTypography.body)
              .copyWith(
                fontSize: (isActive ? 22.0 : 17.0) * fontScale,
                color: isActive ? accent : Colors.white.withValues(alpha: 0.5),
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              );
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 10.w),
            child: AnimatedDefaultTextStyle(
              duration: AppDurations.medium,
              curve: AppCurves.out,
              style: style,
              child: Text(lyrics.lines[i].text, textAlign: TextAlign.center),
            ),
          );
        },
      ),
    );
  }
}

final class _ActiveIndexNotifier extends ValueNotifier<int?> {
  _ActiveIndexNotifier(this.position, this.lyrics)
    : super(lyrics.activeIndex(position.value)) {
    position.addListener(_sync);
  }

  final ValueListenable<Duration> position;
  final Lyrics lyrics;

  void _sync() {
    final next = lyrics.activeIndex(position.value);
    if (next != value) value = next;
  }

  @override
  void dispose() {
    position.removeListener(_sync);
    super.dispose();
  }
}
