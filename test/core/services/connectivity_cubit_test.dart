import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/services/connectivity_cubit.dart';

final class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> controller;

  setUp(() {
    connectivity = _MockConnectivity();
    controller = StreamController<List<ConnectivityResult>>.broadcast();
    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  test('starts online when the initial check reports a connection', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    final cubit = ConnectivityCubit(connectivity: connectivity);
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isTrue);
  });

  test('reports offline when the initial check finds none', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
    final cubit = ConnectivityCubit(connectivity: connectivity);
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isFalse);
  });

  test('stays online when the initial check throws', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenThrow(Exception('no plugin'));
    final cubit = ConnectivityCubit(connectivity: connectivity);
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isTrue);
  });

  test('reacts to connectivity stream changes', () async {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    final cubit = ConnectivityCubit(connectivity: connectivity);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final seen = <bool>[];
    final sub = cubit.stream.listen(seen.add);

    controller.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    controller.add([ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, [false, true]);
    expect(cubit.state, isTrue);
  });
}
