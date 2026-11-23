import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/responsive/animated_branch_stack.dart';

void main() {
  testWidgets('tab reversal continues from the current positions', (
    tester,
  ) async {
    const first = ValueKey('first');
    const second = ValueKey('second');
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: index,
          builder: (context, active, _) => AnimatedBranchStack(
            currentIndex: active,
            children: const [
              Material(child: TextField(key: first)),
              SizedBox.expand(key: second),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(first), 'draft');
    index.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final firstX = tester.getTopLeft(find.byKey(first)).dx;
    final secondX = tester.getTopLeft(find.byKey(second)).dx;
    expect(firstX, lessThan(0));
    expect(secondX, greaterThan(0));

    index.value = 0;
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(first)).dx, closeTo(firstX, 0.01));
    expect(tester.getTopLeft(find.byKey(second)).dx, closeTo(secondX, 0.01));
    await tester.pumpAndSettle();
    expect(find.byKey(second), findsNothing);
    expect(find.text('draft'), findsOneWidget);
  });

  testWidgets('reduced motion parks the old tab on the first frame', (
    tester,
  ) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder(
            valueListenable: index,
            builder: (context, active, _) => AnimatedBranchStack(
              currentIndex: active,
              children: const [Text('First'), Text('Second')],
            ),
          ),
        ),
      ),
    );
    index.value = 1;
    await tester.pump();
    expect(find.text('First'), findsNothing);
    expect(tester.getTopLeft(find.text('Second')).dx, 0);
  });
}
