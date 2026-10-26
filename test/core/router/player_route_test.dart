import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/player_route.dart';
import 'package:aura_music/core/router/routes.dart';

void main() {
  late GoRouter router;

  List<RouteBase> routes() => [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => openPlayer(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.player,
      builder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => closePlayer(context),
                child: const Text('close'),
              ),
              TextButton(
                onPressed: () => openPlayer(context),
                child: const Text('open-again'),
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  setUp(() {
    router = GoRouter(initialLocation: AppRoutes.home, routes: routes());
  });

  tearDown(() => router.dispose());

  testWidgets('openPlayer pushes the player and closePlayer returns home', (
    tester,
  ) async {
    await pump(tester);
    expect(router.state.uri.path, AppRoutes.home);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.player);
    expect(find.text('close'), findsOneWidget);
    expect(
      router.canPop(),
      isTrue,
      reason: 'the tab shell must stay underneath',
    );

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('opening the player while it is on top does not stack it', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open-again'));
    await tester.pumpAndSettle();

    expect(find.text('close'), findsOneWidget);

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closing a cold-start player falls back to home', (tester) async {
    router.dispose();
    router = GoRouter(initialLocation: AppRoutes.player, routes: routes());

    await pump(tester);
    expect(router.canPop(), isFalse);

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    expect(find.text('open'), findsOneWidget);
  });
}
