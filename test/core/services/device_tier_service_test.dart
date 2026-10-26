import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/device_tier_service.dart';

void main() {
  late DeviceTierService service;

  setUp(() => service = DeviceTierService());
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    service.dispose();
  });

  test('defaults to high before probing', () {
    expect(service.tier.value, GlassTier.high);
  });

  test('android probe without plugin access falls back to mid', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await service.probe();
    expect(service.tier.value, GlassTier.mid);
  });

  test('non-android platform resolves to high', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await service.probe();
    expect(service.tier.value, GlassTier.high);
  });

  test('probe is a no-op once it has run (unless forced)', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await service.probe();
    service.applyOverride(GlassTier.low);

    await service.probe(); // not forced -> keeps override
    expect(service.tier.value, GlassTier.low);

    await service.probe(force: true); // forced -> re-probes to high
    expect(service.tier.value, GlassTier.high);
  });

  test('applyOverride(null) leaves the value untouched', () {
    service.applyOverride(GlassTier.mid);
    service.applyOverride(null);
    expect(service.tier.value, GlassTier.mid);
  });

  test('notifies listeners when the tier changes', () {
    var notifications = 0;
    service.tier.addListener(() => notifications++);
    service.applyOverride(GlassTier.low);
    expect(notifications, 1);
  });
}
