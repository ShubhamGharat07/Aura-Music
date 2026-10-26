import 'package:equatable/equatable.dart';

import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Home state (PRD S03). Each network section carries its own status so the
/// UI loads them independently.

/// Section load state.
enum SectionStatus {
  /// Fetch in flight.
  loading,

  /// Has items.
  ready,

  /// Loaded but empty (hidden).
  empty,

  /// Fetch failed.
  error,
}

/// One independently-loaded track section.
final class TrackSection extends Equatable {
  /// Creates a section (loading by default).
  const TrackSection({
    this.status = SectionStatus.loading,
    this.tracks = const [],
    this.error,
  });

  /// A section holding [tracks] (`empty` when the list is empty).
  factory TrackSection.ready(List<Track> tracks) => TrackSection(
    status: tracks.isEmpty ? SectionStatus.empty : SectionStatus.ready,
    tracks: tracks,
  );

  /// A failed section carrying [message].
  factory TrackSection.failed(String message) =>
      TrackSection(status: SectionStatus.error, error: message);

  /// Current status.
  final SectionStatus status;

  /// Section tracks.
  final List<Track> tracks;

  /// Error message when [status] is [SectionStatus.error].
  final String? error;

  /// Copies with overrides.
  TrackSection copyWith({
    SectionStatus? status,
    List<Track>? tracks,
    String? error,
  }) => TrackSection(
    status: status ?? this.status,
    tracks: tracks ?? this.tracks,
    error: error,
  );

  @override
  List<Object?> get props => [status, tracks, error];
}

/// One independently-loaded album section.
final class AlbumSection extends Equatable {
  /// Creates a section (loading by default).
  const AlbumSection({
    this.status = SectionStatus.loading,
    this.albums = const [],
    this.error,
  });

  /// A section holding [albums] (`empty` when the list is empty).
  factory AlbumSection.ready(List<Album> albums) => AlbumSection(
    status: albums.isEmpty ? SectionStatus.empty : SectionStatus.ready,
    albums: albums,
  );

  /// A failed section carrying [message].
  factory AlbumSection.failed(String message) =>
      AlbumSection(status: SectionStatus.error, error: message);

  /// Current status.
  final SectionStatus status;

  /// Section albums.
  final List<Album> albums;

  /// Error message when [status] is [SectionStatus.error].
  final String? error;

  /// Copies with overrides.
  AlbumSection copyWith({
    SectionStatus? status,
    List<Album>? albums,
    String? error,
  }) => AlbumSection(
    status: status ?? this.status,
    albums: albums ?? this.albums,
    error: error,
  );

  @override
  List<Object?> get props => [status, albums, error];
}

/// One independently-loaded artist section.
final class ArtistSection extends Equatable {
  /// Creates a section (loading by default).
  const ArtistSection({
    this.status = SectionStatus.loading,
    this.artists = const [],
    this.error,
  });

  /// A section holding [artists] (`empty` when the list is empty).
  factory ArtistSection.ready(List<Artist> artists) => ArtistSection(
    status: artists.isEmpty ? SectionStatus.empty : SectionStatus.ready,
    artists: artists,
  );

  /// A failed section carrying [message].
  factory ArtistSection.failed(String message) =>
      ArtistSection(status: SectionStatus.error, error: message);

  /// Current status.
  final SectionStatus status;

  /// Section artists.
  final List<Artist> artists;

  /// Error message when [status] is [SectionStatus.error].
  final String? error;

  /// Copies with overrides.
  ArtistSection copyWith({
    SectionStatus? status,
    List<Artist>? artists,
    String? error,
  }) => ArtistSection(
    status: status ?? this.status,
    artists: artists ?? this.artists,
    error: error,
  );

  @override
  List<Object?> get props => [status, artists, error];
}

/// Immutable home state.
final class HomeState extends Equatable {
  /// Creates the state.
  const HomeState({
    this.trending = const TrackSection(),
    this.newReleases = const TrackSection(),
    this.becauseYou = const TrackSection(status: SectionStatus.empty),
    this.genres = const [],
    this.genresStatus = SectionStatus.loading,
    this.selectedGenre,
    this.genreTracks = const TrackSection(status: SectionStatus.empty),
    this.selectedLanguage,
    this.languageTracks = const TrackSection(status: SectionStatus.empty),
    this.newAlbums = const AlbumSection(),
    this.trendingAlbums = const AlbumSection(),
    this.artists = const ArtistSection(),
    this.continueListening = const [],
    this.seedArtist,
    this.offline = false,
  });

  /// Quick picks + trending.
  final TrackSection trending;

  /// New releases.
  final TrackSection newReleases;

  /// "Because you listened to X".
  final TrackSection becauseYou;

  /// Mood / genre filters offered by the catalog.
  final List<Genre> genres;

  /// Load state of the mood / genre row.
  final SectionStatus genresStatus;

  /// Selected mood / genre (null = the "All" chip).
  final Genre? selectedGenre;

  /// Songs of [selectedGenre]; empty while "All" is selected.
  final TrackSection genreTracks;

  /// Selected language chip (null = the section is collapsed).
  final CatalogLanguage? selectedLanguage;

  /// Songs of [selectedLanguage]; empty while collapsed.
  final TrackSection languageTracks;

  /// Latest album releases.
  final AlbumSection newAlbums;

  /// Trending albums.
  final AlbumSection trendingAlbums;

  /// Popular artists.
  final ArtistSection artists;

  /// Locally-derived continue-listening tracks (newest first).
  final List<Track> continueListening;

  /// Artist seeding [becauseYou] (null = no history yet).
  final String? seedArtist;

  /// True when the feed could not load because the device is offline.
  final bool offline;

  /// Quick picks: the first slice of trending.
  List<Track> get quickPicks => trending.tracks.take(8).toList(growable: false);

  /// True while the first feed load is running.
  bool get isLoading => trending.status == SectionStatus.loading;

  /// Copies with overrides. [clearGenre] / [clearLanguage] reset a filter back
  /// to "off" (a plain null override cannot express that).
  HomeState copyWith({
    TrackSection? trending,
    TrackSection? newReleases,
    TrackSection? becauseYou,
    List<Genre>? genres,
    SectionStatus? genresStatus,
    Genre? selectedGenre,
    TrackSection? genreTracks,
    bool clearGenre = false,
    CatalogLanguage? selectedLanguage,
    TrackSection? languageTracks,
    bool clearLanguage = false,
    AlbumSection? newAlbums,
    AlbumSection? trendingAlbums,
    ArtistSection? artists,
    List<Track>? continueListening,
    String? seedArtist,
    bool? offline,
  }) => HomeState(
    trending: trending ?? this.trending,
    newReleases: newReleases ?? this.newReleases,
    becauseYou: becauseYou ?? this.becauseYou,
    genres: genres ?? this.genres,
    genresStatus: genresStatus ?? this.genresStatus,
    selectedGenre: clearGenre ? null : selectedGenre ?? this.selectedGenre,
    genreTracks: genreTracks ?? this.genreTracks,
    selectedLanguage: clearLanguage
        ? null
        : selectedLanguage ?? this.selectedLanguage,
    languageTracks: languageTracks ?? this.languageTracks,
    newAlbums: newAlbums ?? this.newAlbums,
    trendingAlbums: trendingAlbums ?? this.trendingAlbums,
    artists: artists ?? this.artists,
    continueListening: continueListening ?? this.continueListening,
    seedArtist: seedArtist ?? this.seedArtist,
    offline: offline ?? this.offline,
  );

  @override
  List<Object?> get props => [
    trending,
    newReleases,
    becauseYou,
    genres,
    genresStatus,
    selectedGenre,
    genreTracks,
    selectedLanguage,
    languageTracks,
    newAlbums,
    trendingAlbums,
    artists,
    continueListening,
    seedArtist,
    offline,
  ];
}
