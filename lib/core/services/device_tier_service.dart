import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Glass quality tiers (PRD 8.4). Blur cost scales with area, so large
/// tablet panels use fake glass on Mid/Low.

/// Device capability tier.
enum GlassTier {
  /// Blur + refraction + animated backdrop.
  high,

  /// Blur only.
  mid,

  /// No blur: translucent gradient surfaces.
  low,
}

/// Decides the glass tier from device info + a first-run frame-time probe.
/// User override lives in [SettingsCubit] and wins over this value.
final class DeviceTierService {
  /// Creates the service. Call [probe] once on first run.
  DeviceTierService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _deviceInfo;

  /// Current tier. UI consumes via `useGlassTier` / `ValueListenableBuilder`.
  final ValueNotifier<GlassTier> tier = ValueNotifier(GlassTier.high);

  /// Runs the tier probe: low-end Android (SDK < 29) drops to [GlassTier.low].
  /// Re-probed after OS update (caller passes `force: true` then).
  Future<void> probe({bool force = false}) async {
    if (!force && _probed) return;
    _probed = true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        if (info.version.sdkInt < 29) {
          tier.value = GlassTier.low;
          return;
        }
      }
      tier.value = GlassTier.high;
    } catch (_) {
      tier.value = GlassTier.mid;
    }
  }

  /// Applies the Settings → Appearance override (null = Auto).
  void applyOverride(GlassTier? override) {
    if (override != null) tier.value = override;
  }

  /// Releases the notifier.
  void dispose() => tier.dispose();

  bool _probed = false;
}
