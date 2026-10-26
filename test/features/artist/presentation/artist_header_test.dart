import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/artist/presentation/widgets/artist_header.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders name, formatted followers and Play', (tester) async {
    await pumpApp(
      tester,
      const ArtistHeader(
        artist: Artist(id: 'ar1', name: 'Arijit Singh'),
        followerCount: 1500000,
        onPlay: _noop,
      ),
    );

    expect(find.text('Arijit Singh'), findsOneWidget);
    expect(find.text('1.5M followers'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}

void _noop() {}
