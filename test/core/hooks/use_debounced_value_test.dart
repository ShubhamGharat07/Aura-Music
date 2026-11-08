import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/hooks/use_debounced_value.dart';

void main() {
  testWidgets('emits only the last value after rapid changes', (tester) async {
    final emitted = <String>[];
    late TextEditingController controller;

    await tester.pumpWidget(
      MaterialApp(
        home: HookBuilder(
          builder: (context) {
            controller = useTextEditingController();
            useListenable(controller);
            final value = useDebouncedValue(
              controller.text,
              const Duration(milliseconds: 300),
            );
            useEffect(() {
              emitted.add(value);
              return null;
            }, [value]);
            return const SizedBox();
          },
        ),
      ),
    );

    controller.text = 'n';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller.text = 'ne';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller.text = 'neo';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));

    expect(emitted, <String>['']);

    await tester.pump(const Duration(milliseconds: 1));

    expect(emitted, <String>['', 'neo']);
  });

  testWidgets('flushes the stable value once the delay elapses', (
    tester,
  ) async {
    final emitted = <String>[];
    late TextEditingController controller;

    await tester.pumpWidget(
      MaterialApp(
        home: HookBuilder(
          builder: (context) {
            controller = useTextEditingController();
            useListenable(controller);
            final value = useDebouncedValue(
              controller.text,
              const Duration(milliseconds: 300),
            );
            useEffect(() {
              emitted.add(value);
              return null;
            }, [value]);
            return const SizedBox();
          },
        ),
      ),
    );

    controller.text = 'neon';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(emitted, <String>['', 'neon']);
  });
}
