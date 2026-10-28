import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/ui/seek_bar.dart';

void main() {
  testWidgets(
    'tap seeks to the tapped fraction and reports buffered progress',
    (tester) async {
      final position = ValueNotifier<Duration>(Duration.zero);
      final buffered = ValueNotifier<Duration>(const Duration(seconds: 60));
      final seeks = <Duration>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: SeekBar(
                  position: position,
                  buffered: buffered,
                  duration: const Duration(minutes: 2),
                  onSeek: seeks.add,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final rect = tester.getRect(find.byType(SeekBar));
      const thumbRadius = 7.0;
      final trackWidth = rect.width - thumbRadius * 2;
      await tester.tapAt(
        Offset(rect.left + thumbRadius + trackWidth * 0.25, rect.top + 15),
      );
      await tester.pump();

      expect(seeks, hasLength(1));
      expect(seeks.single.inSeconds, closeTo(30, 1));

      position.value = const Duration(seconds: 45);
      await tester.pump();
      expect(find.text('0:45'), findsOneWidget);

      position.dispose();
      buffered.dispose();
    },
  );
}
