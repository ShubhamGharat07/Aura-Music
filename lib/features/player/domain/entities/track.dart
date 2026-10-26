import 'package:equatable/equatable.dart';

/// Domain track entity (pure Dart, PRD 5.1).
final class Track extends Equatable {
  /// Creates a track.
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artUrl,
    this.duration = Duration.zero,
    this.streamUrl,
    this.playCount = 0,
  });

  /// Stable source id (YouTube video id / local id).
  final String id;

  /// Track title.
  final String title;

  /// Primary artist.
  final String artist;

  /// Album name.
  final String? album;

  /// Artwork URL (square).
  final String? artUrl;

  /// Track length.
  final Duration duration;

  /// Resolved stream URL (null until the resolver runs, Phase 1).
  final String? streamUrl;

  /// Lifetime play count reported by the source (0 when unknown).
  final int playCount;

  /// Human subtitle: `Artist · Album`.
  String get subtitle =>
      album == null || album!.isEmpty ? artist : '$artist · $album';

  /// Copies with overrides.
  Track copyWith({String? streamUrl, Duration? duration}) => Track(
    id: id,
    title: title,
    artist: artist,
    album: album,
    artUrl: artUrl,
    duration: duration ?? this.duration,
    streamUrl: streamUrl ?? this.streamUrl,
    playCount: playCount,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    album,
    artUrl,
    duration,
    streamUrl,
    playCount,
  ];
}
