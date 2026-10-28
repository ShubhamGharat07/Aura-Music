import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/presentation/bloc/albums_cubit.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/home/presentation/widgets/home_album_grid.dart';
import 'package:aura_music/features/home/presentation/widgets/home_artists.dart';
import 'package:aura_music/features/home/presentation/widgets/home_header.dart';
import 'package:aura_music/features/home/presentation/widgets/home_languages.dart';
import 'package:aura_music/features/home/presentation/widgets/home_moods.dart';
import 'package:aura_music/features/home/presentation/widgets/home_offline.dart';
import 'package:aura_music/features/home/presentation/widgets/home_quick_picks.dart';
import 'package:aura_music/features/home/presentation/widgets/home_track_section.dart';
import 'package:aura_music/features/home/presentation/widgets/home_your_playlists.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Per-window-class sizing for the home feed (PRD S03).

/// Home feed metrics.
final class HomeFeedLayout {
  /// Creates the layout metrics.
  const HomeFeedLayout({
    required this.padding,
    required this.quickPickColumns,
    required this.cardWidth,
    required this.carouselHeight,
    required this.playlistCardWidth,
    required this.showArrows,
  });

  /// Compact phone metrics.
  const HomeFeedLayout.compact()
    : padding = 20,
      quickPickColumns = 3,
      cardWidth = 156,
      carouselHeight = 226,
      playlistCardWidth = 164,
      showArrows = false;

  /// Medium / Expanded / Large metrics.
  const HomeFeedLayout.wide()
    : padding = 28,
      quickPickColumns = 6,
      cardWidth = 176,
      carouselHeight = 246,
      playlistCardWidth = 184,
      showArrows = true;

  /// Horizontal inset.
  final double padding;

  /// Quick-picks grid columns.
  final int quickPickColumns;

  /// Carousel card width.
  final double cardWidth;

  /// Carousel height.
  final double carouselHeight;

  /// Playlist card width.
  final double playlistCardWidth;

  /// Arrow buttons on carousels.
  final bool showArrows;
}

/// Builds the whole home feed as ONE lazy sliver.
///
/// Every section is a box in a [SliverList], so only the sections around the
/// viewport are built and laid out: the first paint costs the header plus the
/// first couple of sections instead of all eleven (which used to build every
/// grid, carousel and image on the frame Home opened). Off-screen sections are
/// built as the user scrolls towards them.
///
/// Sections intentionally have no entrance animation: a fade/slide that
/// restarts whenever a section is rebuilt made the feed feel like it was
/// chasing the finger, especially when scrolling back up.
Widget homeFeedSliver(
  BuildContext context,
  HomeState state,
  HomeFeedLayout layout,
) {
  final sections = _sectionList(context, state, layout);
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) => sections[index],
      childCount: sections.length,
    ),
  );
}

/// The feed sections in order, each a box for [homeFeedSliver] to host.
///
/// Cheap to call: it only creates widget *instances*, their elements and
/// `build` calls happen for the sections [homeFeedSliver] actually shows.
List<Widget> _sectionList(
  BuildContext context,
  HomeState state,
  HomeFeedLayout layout,
) {
  final bloc = context.read<HomeBloc>();
  final shortWindow = MediaQuery.sizeOf(context).height < 500;
  void retry() => bloc.add(const HomeRefreshed());
  void openSearch() => context.go(AppRoutes.search);

  Widget carouselFor(
    String title,
    TrackSection section, {
    VoidCallback? onSeeAll,
  }) => SectionSwap(
    status: section.status,
    child: HomeTrackSection(
      title: title,
      section: section,
      padding: layout.padding,
      cardWidth: layout.cardWidth,
      height: layout.carouselHeight,
      onSeeAll: onSeeAll,
      onRetry: retry,
      // Overlay arrows eat a card's width on a short landscape phone. Touch
      // scrolling is enough there; keep them for tablet/desktop heights.
      showArrows: layout.showArrows && !shortWindow,
    ),
  );

  // Only the section whose own slice changes rebuilds, instead of the whole
  // feed. Without this every section arrival (e.g. new releases) rebuilt and
  // relaid out the whole CustomScrollView, causing long scroll frames.
  Widget carousel(
    String title,
    TrackSection Function(HomeState state) select, {
    VoidCallback? onSeeAll,
  }) => BlocSelector<HomeBloc, HomeState, TrackSection>(
    selector: select,
    builder: (context, section) =>
        carouselFor(title, section, onSeeAll: onSeeAll),
  );

  Widget continueListening() => BlocSelector<HomeBloc, HomeState, List<Track>>(
    selector: (state) => state.continueListening,
    builder: (context, tracks) => carouselFor(
      'Continue listening',
      TrackSection(
        status: tracks.isEmpty ? SectionStatus.empty : SectionStatus.ready,
        tracks: tracks,
      ),
    ),
  );

  // Slice trending so the six-song opener and the Trending carousel do not
  // repeat the same songs.
  const quickPickCount = 6;

  final selectedGenre = state.selectedGenre;
  final selectedLanguage = state.selectedLanguage;

  return [
    HomeHeader(padding: layout.padding),
    if (state.offline) ...[
      HomeOffline(padding: layout.padding),
      continueListening(),
    ] else ...[
      BlocSelector<HomeBloc, HomeState, TrackSection>(
        selector: (state) => state.trending,
        builder: (context, section) => SectionSwap(
          status: section.status,
          child: HomeQuickPicks(
            section: section,
            padding: layout.padding,
            columns: layout.quickPickColumns,
            onRetry: retry,
          ),
        ),
      ),
      HomeLanguages(
        padding: layout.padding,
        languages: kCatalogLanguages,
        selected: selectedLanguage,
        onSelect: (language) => bloc.add(HomeLanguageSelected(language)),
      ),
      BlocSelector<
        HomeBloc,
        HomeState,
        ({List<Genre> genres, SectionStatus status, Genre? selected})
      >(
        selector: (state) => (
          genres: state.genres,
          status: state.genresStatus,
          selected: state.selectedGenre,
        ),
        builder: (context, data) => SectionSwap(
          status: data.status,
          child: HomeMoods(
            padding: layout.padding,
            genres: data.genres,
            selected: data.selected,
            onSelect: (genre) => bloc.add(HomeGenreSelected(genre)),
          ),
        ),
      ),
      if (selectedGenre == null) ...[
        if (selectedLanguage != null)
          carousel(
            '${selectedLanguage.name} picks',
            (state) => state.languageTracks,
          ),
        continueListening(),
        BlocSelector<HomeBloc, HomeState, TrackSection>(
          selector: (state) => state.trending,
          builder: (context, section) {
            final remaining = section.tracks.length > quickPickCount
                ? section.tracks.skip(quickPickCount).toList(growable: false)
                : section.tracks;
            return carouselFor(
              'Trending now',
              section.copyWith(tracks: remaining),
              onSeeAll: openSearch,
            );
          },
        ),
        carousel(
          'New releases',
          (state) => state.newReleases,
          onSeeAll: openSearch,
        ),
        if (state.seedArtist != null)
          carousel(
            'Because you listened to ${state.seedArtist}',
            (state) => state.becauseYou,
            onSeeAll: openSearch,
          ),
        BlocSelector<HomeBloc, HomeState, ArtistSection>(
          selector: (state) => state.artists,
          builder: (context, section) => SectionSwap(
            status: section.status,
            child: HomeArtists(
              section: section,
              padding: layout.padding,
              onRetry: retry,
            ),
          ),
        ),
        BlocSelector<HomeBloc, HomeState, AlbumSection>(
          selector: (state) => state.newAlbums,
          builder: (context, section) => SectionSwap(
            status: section.status,
            child: HomeAlbumGrid(
              title: 'New albums',
              section: section,
              padding: layout.padding,
              onSeeAll: () => context.push(
                '${AppRoutes.albums}/${AlbumsKind.newAlbums.slug}',
              ),
              onRetry: retry,
            ),
          ),
        ),
        BlocSelector<HomeBloc, HomeState, AlbumSection>(
          selector: (state) => state.trendingAlbums,
          builder: (context, section) => SectionSwap(
            status: section.status,
            child: HomeAlbumGrid(
              title: 'Trending albums',
              section: section,
              padding: layout.padding,
              onSeeAll: () => context.push(
                '${AppRoutes.albums}/${AlbumsKind.trending.slug}',
              ),
              onRetry: retry,
            ),
          ),
        ),
      ] else ...[
        carousel(selectedGenre.name, (state) => state.genreTracks),
        if (selectedLanguage != null)
          carousel(
            '${selectedLanguage.name} picks',
            (state) => state.languageTracks,
          ),
      ],
    ],
    HomeYourPlaylists(
      padding: layout.padding,
      cardWidth: layout.playlistCardWidth,
    ),
    SizedBox(height: MediaQuery.paddingOf(context).bottom + 28.w),
  ];
}

/// Cross-fades a section when its own status changes, so a section that was
/// showing a skeleton fades its content in the moment the data lands instead of
/// snapping. Keyed by [status], so a rebuild for any other reason never
/// restarts the fade.
final class SectionSwap extends StatelessWidget {
  /// Creates a status-aware section wrapper.
  const SectionSwap({super.key, required this.status, required this.child});

  /// Status of the section's own data.
  final SectionStatus status;

  /// Section content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDurations.medium,
      switchInCurve: Curves.easeOut,
      switchOutCurve: AppCurves.out,
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
