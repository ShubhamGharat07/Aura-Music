import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/database/app_database.dart';
import 'package:aura_music/database/daos/liked_songs_dao.dart';
import 'package:aura_music/features/library/data/repositories/liked_songs_repository_impl.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

void main() {
  late AppDatabase db;
  late DriftLikedSongsRepository repository;

  const kesariya = Track(
    id: 'jiosaavn:1',
    title: 'Kesariya',
    artist: 'Arijit Singh',
    album: 'Brahmastra',
    duration: Duration(minutes: 4),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLikedSongsRepository(LikedSongsDao(db));
  });
  tearDown(() => db.close());

  test('toggle adds then removes, reporting the new state', () async {
    expect(await repository.toggle(kesariya), isTrue);
    expect(await repository.isLiked(kesariya.id), isTrue);
    expect((await repository.all()).single.title, 'Kesariya');

    expect(await repository.toggle(kesariya), isFalse);
    expect(await repository.isLiked(kesariya.id), isFalse);
    expect(await repository.all(), isEmpty);
  });

  test('watchLiked emits the liked list on change', () async {
    final emissions = <List<Track>>[];
    final sub = repository.watchLiked().listen(emissions.add);

    await repository.toggle(kesariya);
    await pumpEventQueue();

    expect(emissions.last.single.id, kesariya.id);
    await sub.cancel();
  });

  test('all orders most recently liked first', () async {
    await repository.toggle(kesariya);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.toggle(
      const Track(id: 'jiosaavn:2', title: 'Apna Bana Le', artist: 'A'),
    );

    final all = await repository.all();
    expect(all.first.id, 'jiosaavn:2');
  });

  test('remove and clear drop rows', () async {
    await repository.toggle(kesariya);
    await repository.remove(kesariya.id);
    expect(await repository.all(), isEmpty);

    await repository.toggle(kesariya);
    await repository.clear();
    expect(await repository.all(), isEmpty);
  });
}
