import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/library/domain/entities/history_entry.dart';
import 'package:aura_music/features/library/domain/repositories/play_history_repository.dart';
import 'package:aura_music/features/library/domain/usecases/clear_history.dart';
import 'package:aura_music/features/library/domain/usecases/watch_history.dart';
import 'package:aura_music/features/library/presentation/bloc/history_cubit.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

final class _MockHistoryRepository extends Mock
    implements PlayHistoryRepository {}

void main() {
  late _MockHistoryRepository repository;
  late HistoryCubit cubit;

  final today = DateTime(2026, 10, 16, 9);
  final yesterday = DateTime(2026, 10, 15, 20);

  final entries = [
    HistoryEntry(
      track: const Track(id: 'h1', title: 'Neon', artist: 'A'),
      playedAt: today,
    ),
    HistoryEntry(
      track: const Track(id: 'h2', title: 'Glass', artist: 'B'),
      playedAt: today.subtract(const Duration(hours: 1)),
    ),
    HistoryEntry(
      track: const Track(id: 'h3', title: 'Haze', artist: 'C'),
      playedAt: yesterday,
    ),
  ];

  setUp(() {
    repository = _MockHistoryRepository();
    cubit = HistoryCubit(WatchHistory(repository), ClearHistory(repository));
    addTearDown(cubit.close);
  });

  test('load streams entries into the ready state', () async {
    when(
      () => repository.watchRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(entries));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, HistoryStatus.ready);
    expect(cubit.state.entries, entries);
  });

  test('an empty stream yields the empty state', () async {
    when(
      () => repository.watchRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(const []));

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, HistoryStatus.empty);
  });

  test('groups entries by calendar day preserving order', () async {
    when(
      () => repository.watchRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value(entries));

    await cubit.load();
    await pumpEventQueue();

    final groups = cubit.state.groups;
    expect(groups, hasLength(2));
    expect(groups.first.entries.map((e) => e.track.id), ['h1', 'h2']);
    expect(groups.last.entries.single.track.id, 'h3');
  });

  test('clear delegates to the repository', () async {
    when(() => repository.clear()).thenAnswer((_) async {});

    await cubit.clear();

    verify(() => repository.clear()).called(1);
  });
}
