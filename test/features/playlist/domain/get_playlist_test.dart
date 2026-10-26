import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist_detail.dart';
import 'package:aura_music/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:aura_music/features/playlist/domain/usecases/get_playlist.dart';

final class _MockPlaylistRepository extends Mock
    implements PlaylistRepository {}

void main() {
  late _MockPlaylistRepository repository;
  late GetPlaylist usecase;

  setUp(() {
    repository = _MockPlaylistRepository();
    usecase = GetPlaylist(repository);
  });

  test(
    'blank id short-circuits to a failure without hitting the repo',
    () async {
      final result = await usecase('   ');

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.playlist(any()));
    },
  );

  test('delegates a trimmed id to the repository', () async {
    when(() => repository.playlist('pl1')).thenAnswer(
      (_) async => const Right(
        PlaylistDetail(
          playlist: Playlist(id: 'pl1', title: 'Love'),
        ),
      ),
    );

    await usecase(' pl1 ');

    verify(() => repository.playlist('pl1')).called(1);
  });
}
