import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';

// Now Playing is a root-level route, so it is *pushed* on top of the tab shell
// instead of `go`-ing to it: `go` replaces the shell, leaving the pushed page
// with nothing underneath, which makes the collapse button / system back a
// no-op ("stuck" full-screen player) and drops the per-tab state.

/// Opens the full-screen Now Playing route; no-op when it is already open.
void openPlayer(BuildContext context) {
  if (GoRouter.of(context).state.uri.path == AppRoutes.player) return;
  context.push(AppRoutes.player);
}

/// Closes Now Playing. Falls back to Home when the player is the first route
/// (cold start or deep link straight to `/player`), where pop has no target.
void closePlayer(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}
