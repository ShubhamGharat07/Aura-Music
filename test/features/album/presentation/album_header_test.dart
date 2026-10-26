import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/album/presentation/widgets/album_header.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders album title, meta and Play all', (tester) async {
    await pumpApp(
      tester,
      AlbumHeader(
        album: const Album(
          id: 'al1',
          title: 'Bhediya',
          artist: 'Sachin-Jigar',
          year: 2023,
        ),
        songCount: 6,
        onPlayAll: () {},
      ),
    );

    expect(find.text('Bhediya'), findsOneWidget);
    expect(find.textContaining('Sachin-Jigar'), findsOneWidget);
    expect(find.textContaining('6 songs'), findsOneWidget);
    expect(find.text('Play all'), findsOneWidget);
  });

  testWidgets('disables Play all when there are no songs', (tester) async {
    await pumpApp(
      tester,
      const AlbumHeader(
        album: Album(id: 'al2', title: 'Empty', artist: 'X'),
        songCount: 0,
      ),
    );

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Play all'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });
}
