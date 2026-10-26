import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Artist page: metadata + top songs + albums (PRD S10).

/// An artist with their top songs and albums.
final class ArtistDetail extends Equatable {
  /// Creates an artist detail.
  const ArtistDetail({
    required this.artist,
    this.topSongs = const <Track>[],
    this.albums = const <Album>[],
    this.followerCount,
    this.bio,
  });

  /// Artist metadata.
  final Artist artist;

  /// Most popular songs.
  final List<Track> topSongs;

  /// Top albums.
  final List<Album> albums;

  /// Follower count, when known.
  final int? followerCount;

  /// Short biography, when known.
  final String? bio;

  @override
  List<Object?> get props => [artist, topSongs, albums, followerCount, bio];
}
