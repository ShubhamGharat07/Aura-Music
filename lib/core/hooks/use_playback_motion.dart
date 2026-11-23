import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/device_tier_service.dart';

/// Whether a visible playback indicator can run a continuous animation.
bool usePlaybackMotion(BuildContext context, {required bool playing}) {
  final lifecycle = useAppLifecycleState();
  final tier = useMemoized(
    () => getIt.isRegistered<DeviceTierService>()
        ? getIt<DeviceTierService>().tier
        : null,
  );
  useListenable(tier);
  final visible = ModalRoute.isCurrentOf(context) ?? true;
  return playing &&
      visible &&
      TickerMode.valuesOf(context).enabled &&
      (lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false) &&
      tier?.value != GlassTier.low;
}
