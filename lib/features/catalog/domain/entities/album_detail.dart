import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Album with its ordered track list (PRD S09).

/// An album and its songs.
final class AlbumDetail extends Equatable {
  /// Creates an album detail.
  const AlbumDetail({required this.album, this.songs = const <Track>[]});

  /// Album metadata.
  final Album album;

  /// Album songs, in order.
  final List<Track> songs;

  @override
  List<Object?> get props => [album, songs];
}
