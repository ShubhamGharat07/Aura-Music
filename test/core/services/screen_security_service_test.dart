import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/services/screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('aura/screen');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('forwards the secure flag to the platform channel', () async {
    const service = ScreenSecurityService();

    await service.setSecure(true);
    await service.setSecure(false);

    expect(calls.map((c) => c.method), ['setSecure', 'setSecure']);
    expect(calls.map((c) => c.arguments), [true, false]);
  });

  test('ignores a missing platform handler', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    await const ScreenSecurityService().setSecure(true);
  });
}
