import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/core/ui/glass_surface.dart';
import 'package:aura_music/core/ui/song_tile.dart';

// Regression gate for the ListTile-in-glass assertion:
// "ListTile background color or ink splashes may be invisible."
// A ListTile painted on a glass Container (which has a background colour)
// needs its own nearest Material ancestor, otherwise the framework reports
// the error and ink/background effects are lost.

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(393, 852),
  builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('ListTile inside GlassSurface.fake has a Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GlassSurface.fake(
          child: ListTile(title: const Text('Row'), onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Row'), findsOneWidget);
  });

  testWidgets(
    'SwitchListTile inside GlassSurface.fake (settings) does not assert',
    (tester) async {
      await tester.pumpWidget(
        _host(
          GlassSurface.fake(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('AMOLED black'),
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('AMOLED black'), findsOneWidget);
    },
  );

  testWidgets('ListTile inside blurred GlassSurface (sheet) does not assert', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GlassSurface(
          tier: GlassTier.high,
          child: ListTile(title: const Text('Menu')),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('SongTile renders without framework exceptions', (tester) async {
    await tester.pumpWidget(
      _host(const SongTile(title: 'Neon Horizon', subtitle: 'Aurora Skies')),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Neon Horizon'), findsOneWidget);
  });
}
