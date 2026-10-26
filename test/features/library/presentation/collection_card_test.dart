import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/features/library/presentation/widgets/collection_card.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders title and subtitle and fires onTap', (tester) async {
    var tapped = false;
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 160,
          height: 220,
          child: CollectionCard(
            title: 'Alpha',
            subtitle: 'Aurora',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Aurora'), findsOneWidget);

    await tester.tap(find.text('Alpha'));

    expect(tapped, isTrue);
  });
}
