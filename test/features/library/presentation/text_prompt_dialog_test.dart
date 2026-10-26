import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/library/presentation/widgets/text_prompt_dialog.dart';

void main() {
  Future<List<String?>> openDialog(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
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

  testWidgets('confirm returns the entered text', (tester) async {
    final results = await openDialog(tester);
    await tester.enterText(find.byType(TextField), 'Chill');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(results.single, 'Chill');
  });

  testWidgets('cancel dismisses the dialog', (tester) async {
    final results = await openDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(results.single, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
