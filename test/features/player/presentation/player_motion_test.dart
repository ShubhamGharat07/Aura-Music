import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/ui/playing_bars.dart';

void main() {
  testWidgets('equalizer stops when paused, covered, or reduced motion is on', (
    tester,
  ) async {
    final state = ValueNotifier((playing: true, reduced: false, visible: true));
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: state,
          builder: (context, value, _) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: value.reduced),
            child: TickerMode(
              enabled: value.visible,
              child: PlayingBars(color: Colors.white, playing: value.playing),
            ),
          ),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, greaterThan(0));

    state.value = (playing: false, reduced: false, visible: true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);

    state.value = (playing: true, reduced: false, visible: true);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    state.value = (playing: true, reduced: false, visible: false);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);

    state.value = (playing: true, reduced: true, visible: true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
