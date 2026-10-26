import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/usecases/clear_history.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';

/// History load status.

/// Play-history load status.
enum HistoryStatus {
  /// Stream not yet delivered.
  loading,

  /// Has entries.
  ready,

  /// No plays yet.
  empty,

  /// Stream failed.
  error,
}

/// Plays grouped under one calendar day (PRD S15).
final class HistoryGroup extends Equatable {
  /// Creates a day group.
  const HistoryGroup({required this.day, required this.entries});

  /// The day (midnight, local).
  final DateTime day;

  /// Entries played that day, newest first.
  final List<HistoryEntry> entries;

  @override
  List<Object?> get props => [day, entries];
}

/// Immutable play-history state.
final class HistoryState extends Equatable {
  /// Creates the state.
  const HistoryState({
    this.status = HistoryStatus.loading,
    this.entries = const [],
    this.error,
  });

  /// Current status.
  final HistoryStatus status;

  /// All entries (newest first).
  final List<HistoryEntry> entries;

  /// Error message when [status] is [HistoryStatus.error].
  final String? error;

  /// Entries grouped by day, newest day first.
  List<HistoryGroup> get groups {
    final map = <String, List<HistoryEntry>>{};
    final days = <DateTime>[];
    for (final entry in entries) {
      final day = DateTime(
        entry.playedAt.year,
        entry.playedAt.month,
        entry.playedAt.day,
      );
      final key = '${day.year}-${day.month}-${day.day}';
      if (!map.containsKey(key)) {
        map[key] = <HistoryEntry>[];
        days.add(day);
      }
      map[key]!.add(entry);
    }
    return List.unmodifiable([
      for (final day in days)
        HistoryGroup(
          day: day,
          entries: List.unmodifiable(
            map['${day.year}-${day.month}-${day.day}']!,
          ),
        ),
    ]);
  }

  /// Copies with overrides.
  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryEntry>? entries,
    String? error,
  }) {
    return HistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, entries, error];
}

/// Watches local play history and clears it (PRD S15).
final class HistoryCubit extends Cubit<HistoryState> {
  /// Creates the cubit.
  HistoryCubit(this._watch, this._clear) : super(const HistoryState());

  final WatchHistory _watch;
  final ClearHistory _clear;
  StreamSubscription<List<HistoryEntry>>? _sub;

  /// Subscribes to the history stream; stays live with the database.
  Future<void> load() async {
    await _sub?.cancel();
    _sub = _watch().listen(
      (entries) => emit(
        state.copyWith(
          status: entries.isEmpty ? HistoryStatus.empty : HistoryStatus.ready,
          entries: entries,
        ),
      ),
      onError: (_, _) => emit(
        state.copyWith(
          status: HistoryStatus.error,
          error: 'Could not load history',
        ),
      ),
    );
  }

  /// Clears all history.
  Future<void> clear() => _clear();

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
