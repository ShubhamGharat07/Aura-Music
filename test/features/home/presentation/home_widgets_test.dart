import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/ui/glass_chip.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';
import 'package:aura_music/features/catalog/domain/entities/genre.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/home/presentation/widgets/home_album_grid.dart';
import 'package:aura_music/features/home/presentation/widgets/home_artists.dart';
import 'package:aura_music/features/home/presentation/widgets/home_languages.dart';
import 'package:aura_music/features/home/presentation/widgets/home_moods.dart';
import 'package:aura_music/features/home/presentation/widgets/home_offline.dart';

import '../../../helpers/pump_app.dart';

void main() {
  const chill = Genre(id: '16', name: 'Chill');
  const pop = Genre(id: '15', name: 'Pop');
  const hindi = CatalogLanguage(code: 'hindi', name: 'Hindi');
  const marathi = CatalogLanguage(code: 'marathi', name: 'Marathi');
  const mixtape = Album(
    id: '11',
    title: 'Mixtape',
    artist: 'Aurora',
    songCount: 4,
  );
  const score = Album(
    id: '12',
    title: 'Score',
    artist: 'Lumen',
    language: 'tamil',
  );
  const arijit = Artist(id: '459320', name: 'Arijit Singh');
  const shreya = Artist(id: '455926', name: 'Shreya Ghoshal');

  testWidgets('moods render the catalog chips and report the tapped genre', (
    tester,
  ) async {
    Genre? tapped;
    var cleared = false;
    await pumpApp(
      tester,
      HomeMoods(
        padding: 16,
        genres: const [pop, chill],
        selected: pop,
        onSelect: (genre) {
          if (genre == null) {
            cleared = true;
          } else {
            tapped = genre;
          }
        },
      ),
    );

    expect(find.text(kHomeMoodsAllLabel), findsOneWidget);
    expect(find.text('Pop'), findsOneWidget);
    expect(find.text('Chill'), findsOneWidget);
    expect(find.byType(GlassChip), findsNWidgets(3));
    expect(
      tester
          .widget<GlassChip>(
            find.ancestor(
              of: find.text('Pop'),
              matching: find.byType(GlassChip),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Chill'));
    await tester.pump();
    expect(tapped, chill);

    await tester.tap(find.text(kHomeMoodsAllLabel));
    await tester.pump();
    expect(cleared, isTrue);
  });

  testWidgets('offline view offers the local shortcuts', (tester) async {
    await pumpApp(tester, const HomeOffline(padding: 16));

    expect(find.textContaining('offline'), findsWidgets);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Liked songs'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('languages render the catalog chips and report the tapped one', (
    tester,
  ) async {
    CatalogLanguage? tapped;
    await pumpApp(
      tester,
      HomeLanguages(
        padding: 16,
        languages: const [hindi, marathi],
        selected: marathi,
        onSelect: (language) => tapped = language,
      ),
    );

    expect(find.text('Languages'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Marathi'), findsOneWidget);
    expect(
      tester
          .widget<GlassChip>(
            find.ancestor(
              of: find.text('Marathi'),
              matching: find.byType(GlassChip),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Hindi'));
    await tester.pump();

    expect(tapped, hindi);
  });

  testWidgets('album grid renders one card per album with a usable subtitle', (
    tester,
  ) async {
    var seeAll = 0;
    await pumpApp(
      tester,
      HomeAlbumGrid(
        title: 'New albums',
        section: const AlbumSection(
          status: SectionStatus.ready,
          albums: [mixtape, score],
        ),
        padding: 16,
        onSeeAll: () => seeAll++,
      ),
    );

    expect(find.text('New albums'), findsOneWidget);
    expect(find.text('Mixtape'), findsOneWidget);
    expect(find.text('4 songs'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Tamil'), findsOneWidget);

    await tester.tap(find.text('See all'));
    await tester.pump();

    expect(seeAll, 1);
  });

  testWidgets('an empty album section renders nothing at all', (tester) async {
    await pumpApp(
      tester,
      const HomeAlbumGrid(
        title: 'New albums',
        section: AlbumSection(status: SectionStatus.empty),
        padding: 16,
      ),
    );

    expect(find.text('New albums'), findsNothing);
  });

  testWidgets('artist row renders a circular bubble per artist', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HomeArtists(
        section: ArtistSection(
          status: SectionStatus.ready,
          artists: [arijit, shreya],
        ),
        padding: 16,
      ),
    );

    expect(find.text('Popular artists'), findsOneWidget);
    expect(find.text('Arijit Singh'), findsOneWidget);
    expect(find.text('Shreya Ghoshal'), findsOneWidget);
    expect(find.byType(ClipOval), findsNWidgets(2));
  });

  testWidgets('artist row hides itself when empty and offers retry on error', (
    tester,
  ) async {
    var retries = 0;
    await pumpApp(
      tester,
      Column(
        children: [
          const HomeArtists(
            section: ArtistSection(status: SectionStatus.empty),
            padding: 16,
          ),
          HomeArtists(
            section: const ArtistSection(
              status: SectionStatus.error,
              error: 'Could not load',
            ),
            padding: 16,
            onRetry: () => retries++,
          ),
        ],
      ),
    );

    expect(find.text('Popular artists'), findsOneWidget);
    expect(find.text('Could not load'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retries, 1);
  });
}
