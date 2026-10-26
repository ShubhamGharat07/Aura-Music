import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/ui/measured_height.dart';

void main() {
  testWidgets('reports the initial laid-out height (not just resizes)', (
    tester,
  ) async {
    final height = ValueNotifier<double>(0);
    addTearDown(height.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MeasuredHeight(
            height: height,
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(height.value, 50);
  });

  testWidgets('updates the reported height when the child resizes', (
    tester,
  ) async {
    final height = ValueNotifier<double>(0);
    final childHeight = ValueNotifier<double>(50);
    addTearDown(height.dispose);
    addTearDown(childHeight.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MeasuredHeight(
            height: height,
            child: ValueListenableBuilder<double>(
              valueListenable: childHeight,
              builder: (context, value, _) =>
                  SizedBox(width: 100, height: value),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(height.value, 50);

    childHeight.value = 80;
    await tester.pump();
    await tester.pump();

    expect(height.value, 80);
  });
}
