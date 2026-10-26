import 'package:equatable/equatable.dart';

import 'package:aura_music/features/library/domain/entities/user_playlist.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// A user playlist with its ordered songs (PRD S13).

/// User playlist + songs.
final class UserPlaylistDetail extends Equatable {
  /// Creates the detail.
  const UserPlaylistDetail({required this.playlist, required this.songs});

  /// Playlist metadata (with an up-to-date song count).
  final UserPlaylist playlist;

  /// Songs in playlist order.
  final List<Track> songs;

  @override
  List<Object?> get props => [playlist, songs];
}
