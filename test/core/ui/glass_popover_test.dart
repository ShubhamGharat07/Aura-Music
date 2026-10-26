import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/ui/glass_popover.dart';
import 'package:aura_music/core/ui/glass_surface.dart';

// The popover exists so an overlay never hides behind the system navigation
// bar: these tests pin the anchor-relative placement and the dismiss paths.

Widget _host({
  required Alignment alignment,
  required ValueChanged<BuildContext> onOpen,
}) {
  return ScreenUtilInit(
    designSize: const Size(393, 852),
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => onOpen(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('opens above the anchor when there is room above', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        alignment: Alignment.bottomRight,
        onOpen: (anchor) =>
            GlassPopover.show(anchor, builder: (_) => const Text('panel')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(GlassSurface));
    expect(find.text('panel'), findsOneWidget);
    expect(
      card.bottom,
      lessThanOrEqualTo(tester.getRect(find.text('open')).top),
    );
    expect(card.top, greaterThanOrEqualTo(0));
  });

  testWidgets('flips below the anchor when there is no room above', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        alignment: Alignment.topRight,
        onOpen: (anchor) =>
            GlassPopover.show(anchor, builder: (_) => const Text('panel')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(GlassSurface));
    expect(
      card.top,
      greaterThanOrEqualTo(tester.getRect(find.text('open')).bottom),
    );
  });

  testWidgets('a tap outside dismisses the card', (tester) async {
    await tester.pumpWidget(
      _host(
        alignment: Alignment.bottomRight,
        onOpen: (anchor) =>
            GlassPopover.show(anchor, builder: (_) => const Text('panel')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSurface), findsOneWidget);

    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSurface), findsNothing);
  });

  testWidgets('the system back gesture dismisses the card, not the route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        alignment: Alignment.bottomRight,
        onOpen: (anchor) =>
            GlassPopover.show(anchor, builder: (_) => const Text('panel')),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(GlassSurface), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
