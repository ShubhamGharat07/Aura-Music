import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/router/player_route.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';

/// Enqueues [tracks] starting at [index] in the global [PlayerBloc] and
/// opens the Now Playing screen. Single entry point for "tap to play".

/// Plays [tracks] from [index] and navigates to the player.
void playFromCatalog(BuildContext context, List<Track> tracks, int index) {
  if (tracks.isEmpty) return;
  context.read<PlayerBloc>().add(
    PlayerQueueRequested(tracks, startIndex: index),
  );
  openPlayer(context);
}
