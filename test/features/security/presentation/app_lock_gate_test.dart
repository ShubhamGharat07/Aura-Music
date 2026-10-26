import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/services/biometric_service.dart';
import 'package:aura_music/core/services/screen_security_service.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/repositories/security_repository.dart';
import 'package:aura_music/features/security/domain/usecases/load_security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/update_security_settings.dart';
import 'package:aura_music/features/security/presentation/bloc/security_cubit.dart';
import 'package:aura_music/features/security/presentation/widgets/app_lock_gate.dart';

import '../../../helpers/pump_app.dart';

final class _MockLocalAuth extends Mock implements LocalAuthentication {}

final class _FakeSecurityRepository implements SecurityRepository {
  _FakeSecurityRepository([this.settings = const SecuritySettings.defaults()]);

  SecuritySettings settings;

  @override
  Future<SecuritySettings> load() async => settings;

  @override
  Future<void> save(SecuritySettings value) async => settings = value;
}

void main() {
  late _MockLocalAuth auth;

  setUp(() {
    auth = _MockLocalAuth();
    when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
  });

  SecurityCubit makeCubit({bool appLock = false}) {
    final repository = _FakeSecurityRepository(
      SecuritySettings(appLock: appLock),
    );
    final cubit = SecurityCubit(
      LoadSecuritySettings(repository),
      UpdateSecuritySettings(repository),
      BiometricService(auth: auth),
      const ScreenSecurityService(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  void stubAuth(bool result) {
    when(
      () => auth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        sensitiveTransaction: any(named: 'sensitiveTransaction'),
      ),
    ).thenAnswer((_) async => result);
  }

  testWidgets(
    'overlay shows while locked and hides after a successful unlock',
    (tester) async {
      stubAuth(false);
      final cubit = makeCubit(appLock: true);
      await cubit.load();

      await pumpApp(
        tester,
        BlocProvider<SecurityCubit>.value(
          value: cubit,
          child: const AppLockGate(child: Text('content')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aura Music is locked'), findsOneWidget);

      stubAuth(true);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Aura Music is locked'), findsNothing);
      expect(cubit.state.locked, isFalse);
    },
  );

  testWidgets('gate renders the child directly when the app lock is off', (
    tester,
  ) async {
    final cubit = makeCubit();
    await cubit.load();

    await pumpApp(
      tester,
      BlocProvider<SecurityCubit>.value(
        value: cubit,
        child: const AppLockGate(child: Text('content')),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    expect(find.text('Aura Music is locked'), findsNothing);
  });
}
