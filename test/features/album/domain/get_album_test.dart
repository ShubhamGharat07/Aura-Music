import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/album/domain/usecases/get_album.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

final class _MockAlbumRepository extends Mock implements AlbumRepository {}

void main() {
  late _MockAlbumRepository repository;
  late GetAlbum usecase;

  setUp(() {
    repository = _MockAlbumRepository();
    usecase = GetAlbum(repository);
  });

  test(
    'blank id short-circuits to a failure without hitting the repo',
    () async {
      final result = await usecase('   ');

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.album(any()));
    },
  );

  test('delegates a trimmed id to the repository', () async {
    when(() => repository.album('al1')).thenAnswer(
      (_) async => const Right(
        AlbumDetail(
          album: Album(id: 'al1', title: 'T', artist: 'A'),
        ),
      ),
    );

    await usecase(' al1 ');

    verify(() => repository.album('al1')).called(1);
  });
}
