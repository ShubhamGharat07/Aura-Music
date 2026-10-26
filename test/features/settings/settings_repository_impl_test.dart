import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:aura_music/features/settings/domain/entities/app_settings.dart';

void main() {
  late PrefsSettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = PrefsSettingsRepository(await SharedPreferences.getInstance());
  });

  test('load returns defaults when nothing is stored', () async {
    final settings = await repository.load();
    expect(settings.glassOverride, isNull);
    expect(settings.dynamicColor, isTrue);
    expect(settings.amoled, isFalse);
  });

  test('save then load round-trips every field', () async {
    const settings = AppSettings(
      glassOverride: 'high',
      dynamicColor: false,
      amoled: true,
    );

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('a null glass override removes the stored key (Auto)', () async {
    await repository.save(const AppSettings(glassOverride: 'low'));
    await repository.save(const AppSettings());

    expect((await repository.load()).glassOverride, isNull);
  });
}
