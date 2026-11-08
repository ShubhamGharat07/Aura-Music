import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<List<String?>> openDialog(WidgetTester tester) async {
    final results = <String?>[];
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              results.add(
                await promptForText(
                  context,
                  title: 'New playlist',
                  confirmLabel: 'Create',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('confirm returns the trimmed text', (tester) async {
    final results = await openDialog(tester);
    await tester.enterText(find.byType(TextField), '  Chill  ');
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(results.single, 'Chill');
  });

  testWidgets('create stays disabled until a name is typed', (tester) async {
    await openDialog(tester);

    FilledButton button() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Chill');
    await tester.pump();

    expect(button().onPressed, isNotNull);
  });

  testWidgets('cancel dismisses the dialog', (tester) async {
    final results = await openDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results.single, isNull);
    expect(find.byType(Dialog), findsNothing);
  });
}

