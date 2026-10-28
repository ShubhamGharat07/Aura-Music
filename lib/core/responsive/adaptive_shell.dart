import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/player_route.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/ui/glass_nav_bar.dart';
import 'package:aura_music/core/ui/glass_rail.dart';
import 'package:aura_music/core/ui/measured_height.dart';
import 'package:aura_music/core/ui/mini_player.dart';
import 'package:aura_music/core/ui/offline_banner.dart';
import 'package:aura_music/core/ui/player_bar.dart';
import 'package:aura_music/features/player/domain/entities/playback_status.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';

// Bottom bar <-> rail morph timing. Chrome fades a little faster than the
// rail reveal so the bar is gone before the rail has finished sliding in.
const Duration _morphDuration = Duration(milliseconds: 320);
const Curve _morphCurve = AppCurves.out;
const Duration _chromeFadeDuration = Duration(milliseconds: 200);

/// Adaptive navigation shell (PRD 6.1 + 7.2).
/// Compact -> floating bottom bar; Medium -> rail; Expanded/Large ->
/// extended rail. Mini player docks on Compact/Medium only.
///
/// A single tree morphs between the two chromes: only the rail reveal
/// (clip) and the floating chrome (offset) animate, so rotating or resizing
/// never swaps the tab subtree - which is what used to fling a portrait-sized
/// frame across a landscape window.

/// Shell around the tab [navigationShell].
final class AdaptiveShell extends HookWidget {
  /// Creates the shell.
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
    this.tier = GlassTier.high,
  });

  /// Tab stacks (one per tab, preserved across resize/rotation).
  final StatefulNavigationShell navigationShell;

  /// Glass tier.
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.sizeOf(context);
    final sizeClass = WindowSizeClass.ofWidth(window.width);
    final navigation = WindowSizeClass.navigationFor(
      width: window.width,
      height: window.height,
    );
    final showRail = navigation != ShellNavigationMode.bottomBar;
    // A 240 dp extended rail needs vertical room for its labels: short
    // (landscape phone) windows keep the 80 dp rail instead.
    final extended = navigation == ShellNavigationMode.extendedRail;
    // Reveal width. The rail keeps its natural box and is clipped, so it is
    // never squashed while morphing.
    final railBox = GlassRail.boxWidth(extended: extended);
    final railWidth = showRail ? railBox : 0.0;
    final chromeHeight = useValueNotifier(0.0);
    final backdropKey = useMemoized(BackdropKey.new);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // A class change is a structural relayout, not a navigation flourish:
    // snap to the target chrome so content never reflows for hundreds of ms.
    final previousClass = usePrevious(sizeClass);
    final classChanged = previousClass != null && previousClass != sizeClass;
    final instant = reduceMotion || classChanged;
    final morphDuration = instant ? Duration.zero : _morphDuration;
    final chromeDuration = instant ? Duration.zero : _chromeFadeDuration;

    return Scaffold(
      extendBody: true,
      // Keeps the floating chrome pinned at the bottom (behind the keyboard)
      // instead of riding the IME up on every frame, which would re-rasterise
      // its backdrops. Pages that own a Scaffold inset themselves.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: BackdropGroup(
          backdropKey: backdropKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: morphDuration,
                      curve: _morphCurve,
                      width: railWidth,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: railBox,
                          maxWidth: railBox,
                          child: GlassRail(
                            shell: navigationShell,
                            extended: extended,
                            tier: tier,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<double>(
                        valueListenable: chromeHeight,
                        builder: (context, height, child) =>
                            _BottomInset(bottom: height, child: child!),
                        child: Column(
                          children: [
                            const OfflineBanner(),
                            Expanded(child: navigationShell),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: morphDuration,
                curve: _morphCurve,
                left: railWidth,
                right: 0,
                bottom: 0,
                child: MeasuredHeight(
                  height: chromeHeight,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    // The bottom bar owns the gesture inset on Compact; when the
                    // rail replaces it, the chrome sits on the edge itself.
                    bottom: showRail,
                    child: _Chrome(
                      shell: navigationShell,
                      tier: tier,
                      showBar: !showRail,
                      showPlayerBar: extended,
                      duration: chromeDuration,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating chrome: mini player (or the full player bar) plus, on Compact,
/// the bottom navigation bar.
final class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.shell,
    required this.tier,
    required this.showBar,
    required this.showPlayerBar,
    required this.duration,
  });

  final StatefulNavigationShell shell;
  final GlassTier tier;
  final bool showBar;
  final bool showPlayerBar;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final bar = showBar
        ? Padding(
            key: const ValueKey('bottom-bar'),
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: GlassNavBar(shell: shell, tier: tier),
          )
        : const SizedBox(
            key: ValueKey('no-bottom-bar'),
            width: double.infinity,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPlayerBar)
          _ExpandedPlayerBar(tier: tier)
        else
          MiniPlayer(tier: tier, onTap: () => openPlayer(context)),
        if (duration == Duration.zero)
          bar
        else
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: AppCurves.out,
            child: bar,
          ),
      ],
    );
  }
}

// Content scrolls under the floating chrome, so expose the chrome's real
// height as bottom padding: ListView consumes it automatically and
// CustomScrollView pages (e.g. Home) read it for their end spacer. The chrome
// already includes the device's bottom safe-area inset, so its measured height
// is the full occluded region.
//
// Reading MediaQuery here (a leaf) instead of in the shell is deliberate:
// MediaQuery.of depends on *every* aspect, so the keyboard's per-frame
// viewInsets changes would otherwise rebuild the whole shell - including the
// mini player and nav bar backdrops - on every frame of the IME animation.
final class _BottomInset extends StatelessWidget {
  const _BottomInset({required this.bottom, required this.child});

  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    // While the IME is up it covers the chrome, so the chrome is no longer the
    // occluded region - pages that own an input inset themselves instead.
    final exposed = data.viewInsets.bottom > 0 ? 0.0 : bottom;
    return MediaQuery(
      data: data.copyWith(padding: EdgeInsets.only(bottom: exposed)),
      child: child,
    );
  }
}

/// Full player bar docked on Expanded/Large (PRD 6.1/O6). Hidden until a
/// track is loaded; binds [PlayerBloc] to the presentational [PlayerBar].
final class _ExpandedPlayerBar extends StatelessWidget {
  const _ExpandedPlayerBar({required this.tier});

  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) return const SizedBox.shrink();
        final bloc = context.read<PlayerBloc>();
        return PlayerBar(
          tier: tier,
          position: bloc.controller.position,
          duration: bloc.controller.duration,
          title: track.title,
          subtitle: track.artist,
          artUrl: track.artUrl,
          isPlaying: state.isPlaying,
          busy: state.status == PlaybackStatus.loading,
          onPlayPause: () => bloc.add(const PlayerPlayPauseToggled()),
          onNext: () => bloc.add(const PlayerNextRequested()),
          onPrevious: () => bloc.add(const PlayerPreviousRequested()),
          onSeek: (position) => bloc.add(PlayerSeekRequested(position)),
          onExpand: () => openPlayer(context),
        );
      },
    );
  }
}
