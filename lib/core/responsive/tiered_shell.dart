import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/adaptive_shell.dart';
import 'package:aura_music/core/services/device_tier_service.dart';

/// Binds the probed [GlassTier] to [AdaptiveShell] (PRD 8.4), so low-end
/// devices actually drop blur instead of always rendering the high tier.
///
/// Resolution is defensive: widget tests that mount the router without the
/// full DI graph keep the high tier instead of throwing.
final class TieredShell extends HookWidget {
  /// Creates the shell wrapper.
  const TieredShell({super.key, required this.navigationShell});

  /// Tab stacks (one per tab, preserved across resize/rotation).
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final notifier = useMemoized(_resolveTierNotifier);
    final tier = useValueListenable(notifier);
    return AdaptiveShell(navigationShell: navigationShell, tier: tier);
  }

  static ValueNotifier<GlassTier> _resolveTierNotifier() {
    try {
      return getIt<DeviceTierService>().tier;
    } on Object {
      return ValueNotifier<GlassTier>(GlassTier.high);
    }
  }
}
