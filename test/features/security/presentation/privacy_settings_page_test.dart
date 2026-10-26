import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/services/biometric_service.dart';
import 'package:aura_music/core/services/data_reset_service.dart';
import 'package:aura_music/core/services/screen_security_service.dart';
import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/features/search/domain/repositories/search_history_repository.dart';
import 'package:aura_music/features/search/domain/usecases/clear_recent_searches.dart';
import 'package:aura_music/features/security/data/repositories/security_repository_impl.dart';
import 'package:aura_music/features/security/domain/usecases/load_security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/update_security_settings.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';
import 'package:aura_music/features/security/presentation/pages/privacy_settings_page.dart';

import '../../../helpers/pump_app.dart';

final class _FakeSearchHistoryRepository implements SearchHistoryRepository {
  bool cleared = false;

  @override
  Future<List<String>> recent() async => const ['neon'];

  @override
  Future<void> add(String query) async {}

  @override
  Future<void> clear() async => cleared = true;

  @override
  Future<void> remove(String query) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory downloads;
  late _FakeSearchHistoryRepository searchHistory;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    downloads = await Directory.systemTemp.createTemp('aura-privacy');
    searchHistory = _FakeSearchHistoryRepository();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = PrefsSecurityRepository(prefs);
    getIt.registerSingleton<ClearRecentSearches>(
      ClearRecentSearches(searchHistory),
    );
    getIt.registerSingleton<DataResetService>(
      DataResetService(db, prefs, downloadsDirectory: () async => downloads),
    );
    getIt.registerSingleton<SecurityCubit>(
      SecurityCubit(
        LoadSecuritySettings(repository),
        UpdateSecuritySettings(repository),
        BiometricService(),
        const ScreenSecurityService(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
    if (downloads.existsSync()) await downloads.delete(recursive: true);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final cubit = getIt<SecurityCubit>();
    await cubit.load();
    await pumpApp(
      tester,
      BlocProvider<SecurityCubit>.value(
        value: cubit,
        child: const PrivacySettingsPage(),
      ),
    );
  }

  testWidgets('toggling pause history persists the preference', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Pause listening history'));
    await tester.pumpAndSettle();

    expect(getIt<SecurityCubit>().state.settings.pauseHistory, isTrue);
  });

  testWidgets('clear all data requires the keyword and wipes local state', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.ensureVisible(find.text('Clear all data'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear all data'));
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(FilledButton, 'Delete everything');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(await db.select(db.likedSongs).get(), isEmpty);
    expect(find.text('All local data cleared'), findsOneWidget);
  });

  testWidgets('clear search history confirms before clearing', (tester) async {
    await pumpPage(tester);
    await tester.ensureVisible(find.text('Clear search history'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear search history'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(searchHistory.cleared, isTrue);
  });
}
