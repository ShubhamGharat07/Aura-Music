import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/liked_tracks_header.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders count, Play, Shuffle and the sort label', (
    tester,
  ) async {
    await pumpApp(
      tester,
      LikedTracksHeader(
        count: 3,
        sort: LikedSort.title,
        onPlay: () {},
        onShuffle: () {},
        onCycleSort: () {},
      ),
    );

    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
  });

  testWidgets('singularises a single song and fires callbacks', (tester) async {
    var played = 0;
    var shuffled = 0;
    var sorted = 0;
    await pumpApp(
      tester,
      LikedTracksHeader(
        count: 1,
        sort: LikedSort.recent,
        onPlay: () => played++,
        onShuffle: () => shuffled++,
        onCycleSort: () => sorted++,
      ),
    );

    expect(find.text('1 song'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.tap(find.text('Shuffle'));
    await tester.tap(find.text('Recent'));
    await tester.pump();

    expect(played, 1);
    expect(shuffled, 1);
    expect(sorted, 1);
  });
}
