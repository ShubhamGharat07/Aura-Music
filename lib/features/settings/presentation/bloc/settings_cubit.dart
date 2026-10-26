import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/core/services/device_tier_service.dart';
import 'package:aura_music/features/settings/domain/entities/app_settings.dart';
import 'package:aura_music/features/settings/domain/repositories/settings_repository.dart';

/// Global settings state (PRD 4.1). Persisted via [SettingsRepository].
/// Widgets never read prefs directly.

/// Settings state (immutable).
final class SettingsState extends Equatable {
  /// Creates settings state.
  const SettingsState({this.settings = const AppSettings.defaults()});

  /// Current settings.
  final AppSettings settings;

  /// Glass override as enum (null = Auto).
  GlassTier? get glassTier => switch (settings.glassOverride) {
    'high' => GlassTier.high,
    'mid' => GlassTier.mid,
    'low' => GlassTier.low,
    _ => null,
  };

  /// Copies with a new snapshot.
  SettingsState copyWith({AppSettings? settings}) =>
      SettingsState(settings: settings ?? this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Global settings cubit.
final class SettingsCubit extends Cubit<SettingsState> {
  /// Creates the cubit. Call [load] after DI bootstrap.
  SettingsCubit(this._repo, this._tiers) : super(const SettingsState());

  final SettingsRepository _repo;
  final DeviceTierService _tiers;
  Future<void> _saveTail = Future<void>.value();

  /// Loads persisted settings and applies the glass override.
  Future<void> load() async {
    final settings = await _repo.load();
    _tiers.applyOverride(_tierOf(settings));
    emit(SettingsState(settings: settings));
  }

  /// Sets the glass override (null = Auto).
  Future<void> setGlassTier(GlassTier? tier) async {
    final name = tier?.name;
    final next = state.settings.copyWith(
      glassOverride: name,
      clearGlass: tier == null,
    );
    emit(state.copyWith(settings: next));
    _tiers.applyOverride(tier);
    if (tier == null) {
      await _tiers.probe(force: true); // re-probe on Auto
      _tiers.applyOverride(null);
    }
    await _persist(next);
  }

  /// Toggles dynamic colour.
  Future<void> setDynamicColor(bool value) async {
    final next = state.settings.copyWith(dynamicColor: value);
    emit(state.copyWith(settings: next));
    await _persist(next);
  }

  /// Toggles AMOLED theme.
  Future<void> setAmoled(bool value) async {
    final next = state.settings.copyWith(amoled: value);
    emit(state.copyWith(settings: next));
    await _persist(next);
  }

  /// Sets the playback rate (clamped to 0.75-1.5 by the UI).
  Future<void> setPlaybackSpeed(double value) async {
    final next = state.settings.copyWith(playbackSpeed: value);
    emit(state.copyWith(settings: next));
    await _persist(next);
  }

  /// Toggles skip-silence playback.
  Future<void> setSkipSilence(bool value) async {
    final next = state.settings.copyWith(skipSilence: value);
    emit(state.copyWith(settings: next));
    await _persist(next);
  }

  /// Writes are serialised so rapid tapping can never persist an older value
  /// after a newer one.
  Future<void> _persist(AppSettings next) {
    _saveTail = _saveTail
        .then((_) => _repo.save(next))
        .catchError((Object _) {});
    return _saveTail;
  }

  GlassTier? _tierOf(AppSettings s) => switch (s.glassOverride) {
    'high' => GlassTier.high,
    'mid' => GlassTier.mid,
    'low' => GlassTier.low,
    _ => null,
  };
}
