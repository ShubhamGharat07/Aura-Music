import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:aura_music/core/services/playback/aura_audio_handler.dart';
import 'package:aura_music/core/services/playback/playback_controller.dart';
import 'package:aura_music/features/player/presentation/bloc/player_bloc.dart';
import 'package:aura_music/features/player/presentation/bloc/player_event.dart';
import 'package:aura_music/features/player/presentation/bloc/player_state.dart';

/// Owns the `audio_service` session: initialises the media-session handler and
/// keeps the notification metadata in sync with [PlayerBloc] (PRD F03).
///
/// Every platform call is guarded: on unsupported hosts (widget tests, desktop
/// without the plugin) the app silently runs without a media session.
final class MediaSessionService {
  /// Creates the service.
  MediaSessionService({
    required PlayerBloc player,
    required PlaybackController controller,
  }) : _player = player,
       _controller = controller;

  final PlayerBloc _player;
  final PlaybackController _controller;
  AuraAudioHandler? _handler;
  StreamSubscription<PlayerState>? _stateSub;

  /// The live handler, or null when the session could not start.
  AuraAudioHandler? get handler => _handler;

  /// Starts the session. Safe to call once from bootstrap.
  Future<void> start() async {
    if (_handler != null) return;
    try {
      _handler = await AudioService.init(
        builder: _buildHandler,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.aura_music.playback',
          androidNotificationChannelName: 'Aura Music playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      _stateSub = _player.stream.listen(_sync);
    } on Object {
      _handler = null;
    }
  }

  /// Releases the session subscriptions.
  Future<void> dispose() async {
    await _stateSub?.cancel();
    _stateSub = null;
    await _handler?.disposeHandler();
    _handler = null;
  }

  AuraAudioHandler _buildHandler() => AuraAudioHandler(
    position: _controller.position,
    buffered: _controller.buffered,
    statusStream: _controller.statusStream,
    onPlay: () {
      if (!_player.state.isPlaying) {
        _player.add(const PlayerPlayPauseToggled());
      }
    },
    onPause: () {
      if (_player.state.isPlaying) {
        _player.add(const PlayerPlayPauseToggled());
      }
    },
    onNext: () => _player.add(const PlayerNextRequested()),
    onPrevious: () => _player.add(const PlayerPreviousRequested()),
    onLike: () {
      final track = _player.state.currentTrack;
      if (track != null) _player.add(PlayerLikeToggled(track.id));
    },
    onSeek: (position) => _player.add(PlayerSeekRequested(position)),
  );

  void _sync(PlayerState state) {
    final handler = _handler;
    if (handler == null) return;
    final track = state.currentTrack;
    if (track == null) {
      handler.clearNowPlaying();
      return;
    }
    handler.setNowPlaying(
      MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration > Duration.zero
            ? track.duration
            : _controller.duration,
        artUri: _uri(track.artUrl),
      ),
      hasNext: state.currentIndex + 1 < state.queue.length,
      hasPrevious: state.currentIndex > 0,
      liked: state.isLiked(track.id),
    );
  }

  static Uri? _uri(String? artUrl) {
    if (artUrl == null || artUrl.isEmpty) return null;
    return Uri.tryParse(artUrl);
  }
}
