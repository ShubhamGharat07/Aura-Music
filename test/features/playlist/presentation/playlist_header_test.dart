import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/playlist/presentation/widgets/playlist_header.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders title, subtitle meta and Play all', (tester) async {
    await pumpApp(
      tester,
      PlaylistHeader(
        playlist: const Playlist(
          id: 'pl1',
          title: 'Romance',
          subtitle: 'Best of',
        ),
        songCount: 20,
        onPlayAll: () {},
      ),
    );

    expect(find.text('Romance'), findsOneWidget);
    expect(find.textContaining('Best of'), findsOneWidget);
    expect(find.textContaining('20 songs'), findsOneWidget);
    expect(find.text('Play all'), findsOneWidget);
  });
}
