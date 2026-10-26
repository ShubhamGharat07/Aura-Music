import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/services/biometric_service.dart';
import 'package:aura_music/core/services/screen_security_service.dart';
import 'package:aura_music/core/usecase/usecase.dart';
import 'package:aura_music/features/security/domain/entities/security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/load_security_settings.dart';
import 'package:aura_music/features/security/domain/usecases/update_security_settings.dart';

/// Security & privacy state (PRD S20). `locked` drives the app-lock overlay;
/// `authenticating` suppresses lifecycle re-locks during the prompt.

/// Security state (immutable).
final class SecurityState extends Equatable {
  /// Creates the state.
  const SecurityState({
    this.settings = const SecuritySettings.defaults(),
    this.locked = false,
    this.authenticating = false,
  });

  /// Current preferences.
  final SecuritySettings settings;

  /// Whether the lock overlay is showing.
  final bool locked;

  /// Whether a biometric prompt is in flight.
  final bool authenticating;

  /// Copies with overrides.
  SecurityState copyWith({
    SecuritySettings? settings,
    bool? locked,
    bool? authenticating,
  }) {
    return SecurityState(
      settings: settings ?? this.settings,
      locked: locked ?? this.locked,
      authenticating: authenticating ?? this.authenticating,
    );
  }

  @override
  List<Object?> get props => [settings, locked, authenticating];
}

/// App-lock and privacy cubit.
final class SecurityCubit extends Cubit<SecurityState> {
  /// Creates the cubit. Call [load] after DI bootstrap.
  SecurityCubit(this._load, this._update, this._biometrics, this._screen)
    : super(const SecurityState());

  final LoadSecuritySettings _load;
  final UpdateSecuritySettings _update;
  final BiometricService _biometrics;
  final ScreenSecurityService _screen;

  /// Loads persisted settings, applies FLAG_SECURE and locks when enabled.
  /// Falls back to defaults (lock off) if the store cannot be read, so a
  /// storage failure can never lock the user out.
  Future<void> load() async {
    SecuritySettings settings;
    try {
      final result = await _load(const NoParams());
      settings = result.getOrElse((_) => const SecuritySettings.defaults());
    } on Object {
      settings = const SecuritySettings.defaults();
    }
    await _screen.setSecure(settings.blockScreenshots);
    emit(SecurityState(settings: settings, locked: settings.appLock));
  }

  /// Enables/disables the app lock. Returns false when the device cannot
  /// authenticate, so the caller can surface a message.
  Future<bool> setAppLock(bool value) async {
    if (value && !await _biometrics.isAvailable()) return false;
    final next = state.settings.copyWith(appLock: value);
    await _update(next);
    emit(state.copyWith(settings: next, locked: value));
    return true;
  }

  /// Sets the background grace period.
  Future<void> setLockTimeout(LockTimeout value) =>
      _apply(state.settings.copyWith(lockTimeout: value));

  /// Toggles screenshot blocking.
  Future<void> setBlockScreenshots(bool value) async {
    final next = state.settings.copyWith(blockScreenshots: value);
    await _screen.setSecure(value);
    await _apply(next);
  }

  /// Toggles play-history recording.
  Future<void> setPauseHistory(bool value) =>
      _apply(state.settings.copyWith(pauseHistory: value));

  /// Locks the app immediately (called by the lifecycle gate).
  void lock() {
    if (state.locked || !state.settings.appLock) return;
    emit(state.copyWith(locked: true));
  }

  /// Prompts for biometrics / device credential and unlocks on success.
  Future<void> unlock() async {
    if (state.authenticating) return;
    emit(state.copyWith(authenticating: true));
    final ok = await _biometrics.authenticate(reason: 'Unlock Aura Music');
    emit(state.copyWith(authenticating: false, locked: !ok));
  }

  Future<void> _apply(SecuritySettings next) async {
    await _update(next);
    emit(state.copyWith(settings: next));
  }
}
