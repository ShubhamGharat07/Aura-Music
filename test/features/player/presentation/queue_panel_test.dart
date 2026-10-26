import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/player/domain/entities/track.dart';
import 'package:aura_music/features/player/presentation/widgets/queue_panel.dart';

import '../../../helpers/pump_app.dart';

void main() {
  const tracks = [
    Track(id: 'a', title: 'A', artist: 'X'),
    Track(id: 'b', title: 'B', artist: 'Y'),
    Track(id: 'c', title: 'C', artist: 'Z'),
  ];

  testWidgets('shows the count, pinned track and up-next rows', (tester) async {
    await pumpApp(
      tester,
      QueuePanel(queue: tracks, currentIndex: 0, accent: Colors.teal),
    );

    expect(find.text('3 in queue'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // pinned now-playing
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('tapping an up-next row selects its full-queue index', (
    tester,
  ) async {
    int? selected;
    await pumpApp(
      tester,
      QueuePanel(
        queue: tracks,
        currentIndex: 0,
        accent: Colors.teal,
        onSelect: (index) => selected = index,
      ),
    );

    await tester.tap(find.text('C'));

    expect(selected, 2);
  });

  testWidgets('clear and shuffle are wired for a non-empty up-next', (
    tester,
  ) async {
    var cleared = 0;
    var shuffled = 0;
    await pumpApp(
      tester,
      QueuePanel(
        queue: tracks,
        currentIndex: 0,
        accent: Colors.teal,
        onClear: () => cleared++,
        onShuffle: () => shuffled++,
      ),
    );

    await tester.tap(find.byTooltip('Clear queue'));
    await tester.tap(find.byTooltip('Shuffle queue'));

    expect(cleared, 1);
    expect(shuffled, 1);
  });

  testWidgets('swiping an up-next row removes it', (tester) async {
    int? removed;
    await pumpApp(
      tester,
      QueuePanel(
        queue: tracks,
        currentIndex: 0,
        accent: Colors.teal,
        onRemove: (index) => removed = index,
      ),
    );

    await tester.drag(find.text('B'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(removed, 1);
  });

  testWidgets('shows an empty state when nothing is up next', (tester) async {
    await pumpApp(
      tester,
      QueuePanel(
        queue: const [Track(id: 'a', title: 'A', artist: 'X')],
        currentIndex: 0,
        accent: Colors.teal,
      ),
    );

    expect(find.text('Nothing up next.'), findsOneWidget);
    expect(find.text('1 in queue'), findsOneWidget);
  });
}
