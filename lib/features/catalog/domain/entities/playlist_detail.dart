import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Playlist with its ordered track list (PRD S11).

/// A playlist and its songs.
final class PlaylistDetail extends Equatable {
  /// Creates a playlist detail.
  const PlaylistDetail({required this.playlist, this.songs = const <Track>[]});

  /// Playlist metadata.
  final Playlist playlist;

  /// Playlist songs, in order.
  final List<Track> songs;

  @override
  List<Object?> get props => [playlist, songs];
}
