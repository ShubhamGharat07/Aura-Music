import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// One search response: songs plus album / artist / playlist matches (PRD S05).

/// Grouped search results.
final class SearchResults extends Equatable {
  /// Creates grouped results.
  const SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  /// Matching songs (playable).
  final List<Track> songs;

  /// Matching albums.
  final List<Album> albums;

  /// Matching artists.
  final List<Artist> artists;

  /// Matching playlists.
  final List<Playlist> playlists;

  /// True when nothing matched.
  bool get isEmpty =>
      songs.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;

  /// True when at least one group has matches.
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [songs, albums, artists, playlists];
}
