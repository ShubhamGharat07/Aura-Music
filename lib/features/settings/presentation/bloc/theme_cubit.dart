import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/theme/colors.dart';

/// Global theme state (PRD 4.1). Accent comes from the album-art palette
/// pipeline (DynamicAccentBinder); [setAccent] is its entry point.

/// Theme state (immutable).
final class ThemeState extends Equatable {
  /// Creates theme state.
  const ThemeState({
    this.accent = AppColors.accentDefault,
    this.amoled = false,
  });

  /// Active accent colour.
  final Color accent;

  /// AMOLED pure-black backgrounds.
  final bool amoled;

  /// Copies with overrides.
  ThemeState copyWith({Color? accent, bool? amoled}) =>
      ThemeState(accent: accent ?? this.accent, amoled: amoled ?? this.amoled);

  @override
  List<Object?> get props => [accent, amoled];
}

/// Global theme cubit. Colour tween (400 ms) happens in the UI layer
/// via `AnimatedContainer`/theme animation, never in the cubit.
final class ThemeCubit extends Cubit<ThemeState> {
  /// Creates the theme cubit.
  ThemeCubit() : super(const ThemeState());

  /// Sets the dynamic accent (clamped upstream S 45-75% / L 55-70%).
  void setAccent(Color accent) => emit(state.copyWith(accent: accent));

  /// Sets AMOLED mode (mirrors Settings → Appearance).
  void setAmoled(bool amoled) => emit(state.copyWith(amoled: amoled));
}
