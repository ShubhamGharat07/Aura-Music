import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/router/app_dialog.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> openTypedDialog(
    WidgetTester tester,
    void Function(bool?) onResult,
  ) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              onResult(
                await showTypedConfirmDialog(
                  context,
                  title: 'Clear all data?',
                  message: 'This cannot be undone.',
                  keyword: 'DELETE',
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
  }

  testWidgets('typed confirm stays disabled until the keyword matches', (
    tester,
  ) async {
    bool? result;
    await openTypedDialog(tester, (value) => result = value);

    final button = find.widgetWithText(FilledButton, 'Delete');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('cancel resolves false', (tester) async {
    bool? result;
    await openTypedDialog(tester, (value) => result = value);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('confirm dialog resolves true on confirm', (tester) async {
    bool? result;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              result = await showConfirmDialog(
                context,
                title: 'Clear search history?',
                message: 'Recent terms will be removed.',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
