import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/features/settings/presentation/bloc/theme_cubit.dart';

void main() {
  late ThemeCubit cubit;

  setUp(() {
    cubit = ThemeCubit();
    addTearDown(cubit.close);
  });

  test('starts with the default accent and light AMOLED off', () {
    expect(cubit.state.accent, AppColors.accentDefault);
    expect(cubit.state.amoled, isFalse);
  });

  test('setAccent replaces the accent', () {
    cubit.setAccent(const Color(0xFF00FF00));
    expect(cubit.state.accent, const Color(0xFF00FF00));
  });

  test('setAmoled toggles the black theme', () {
    cubit.setAmoled(true);
    expect(cubit.state.amoled, isTrue);
    cubit.setAmoled(false);
    expect(cubit.state.amoled, isFalse);
  });
}
