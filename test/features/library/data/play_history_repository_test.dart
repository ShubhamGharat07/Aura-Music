import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/history_dao.dart';
import 'package:aura_music/features/library/data/repositories/play_history_repository_impl.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  late AppDatabase db;
  late DriftPlayHistoryRepository repository;

  const neon = Track(
    id: 'jiosaavn:1',
    title: 'Neon',
    artist: 'Aurora',
    duration: Duration(minutes: 3),
  );
  const glass = Track(id: 'jiosaavn:2', title: 'Glass', artist: 'Lumen');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftPlayHistoryRepository(HistoryDao(db));
  });
  tearDown(() => db.close());

  test('record writes a play that recent returns newest first', () async {
    await repository.record(neon);
    await repository.record(glass);

    final recent = await repository.recent();
    expect(recent.map((e) => e.track.id), ['jiosaavn:2', 'jiosaavn:1']);
  });

  test('record keeps the track snapshot fields', () async {
    await repository.record(neon);

    final entry = (await repository.recent()).single;
    expect(entry.track.title, 'Neon');
    expect(entry.track.artist, 'Aurora');
    expect(entry.track.duration, const Duration(minutes: 3));
  });

  test('watchRecent emits on change', () async {
    final emissions = <int>[];
    final sub = repository.watchRecent().listen(
      (entries) => emissions.add(entries.length),
    );

    await repository.record(neon);
    await pumpEventQueue();

    expect(emissions.last, 1);
    await sub.cancel();
  });

  test('clear removes every entry', () async {
    await repository.record(neon);

    await repository.clear();

    expect(await repository.recent(), isEmpty);
  });
}
