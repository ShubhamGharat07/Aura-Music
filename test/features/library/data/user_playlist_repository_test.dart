import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/user_playlists_dao.dart';
import 'package:aura_music/features/library/data/repositories/user_playlist_repository_impl.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  late AppDatabase db;
  late DriftUserPlaylistRepository repository;

  const neon = Track(id: 'jiosaavn:1', title: 'Neon', artist: 'Aurora');
  const glass = Track(id: 'jiosaavn:2', title: 'Glass', artist: 'Lumen');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftUserPlaylistRepository(UserPlaylistsDao(db));
  });
  tearDown(() => db.close());

  test('create returns an id and an empty detail', () async {
    final id = await repository.create('Chill');

    final detail = await repository.detail(id);
    expect(detail, isNotNull);
    expect(detail!.playlist.name, 'Chill');
    expect(detail.songs, isEmpty);
    expect(detail.playlist.songCount, 0);
  });

  test('addTrack appends in order and updates the count', () async {
    final id = await repository.create('Chill');

    await repository.addTrack(id, neon);
    await repository.addTrack(id, glass);

    final detail = await repository.detail(id);
    expect(detail!.songs.map((t) => t.id), ['jiosaavn:1', 'jiosaavn:2']);
    expect(detail.playlist.songCount, 2);
  });

  test('removeTrack drops a track and refreshes the count', () async {
    final id = await repository.create('Chill');
    await repository.addTrack(id, neon);
    await repository.addTrack(id, glass);

    await repository.removeTrack(id, 'jiosaavn:1');

    final detail = await repository.detail(id);
    expect(detail!.songs.single.id, 'jiosaavn:2');
    expect(detail.playlist.songCount, 1);
  });

  test('rename changes the name', () async {
    final id = await repository.create('Chill');

    await repository.rename(id, 'Focus');

    expect((await repository.detail(id))!.playlist.name, 'Focus');
  });

  test('delete cascades the playlist songs away', () async {
    final id = await repository.create('Chill');
    await repository.addTrack(id, neon);

    await repository.delete(id);

    expect(await repository.detail(id), isNull);
  });

  test('watchAll emits after a change', () async {
    final emissions = <int>[];
    final sub = repository.watchAll().listen(
      (playlists) => emissions.add(playlists.length),
    );

    await repository.create('Chill');
    await pumpEventQueue();

    expect(emissions.last, 1);
    await sub.cancel();
  });
}
