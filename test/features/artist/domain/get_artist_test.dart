import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/artist/domain/repositories/artist_repository.dart';
import 'package:aura_music/features/artist/domain/usecases/get_artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

final class _MockArtistRepository extends Mock implements ArtistRepository {}

void main() {
  late _MockArtistRepository repository;
  late GetArtist usecase;

  setUp(() {
    repository = _MockArtistRepository();
    usecase = GetArtist(repository);
  });

  test(
    'blank id short-circuits to a failure without hitting the repo',
    () async {
      final result = await usecase('   ');

      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.artist(any()));
    },
  );

  test('delegates a trimmed id to the repository', () async {
    when(() => repository.artist('ar1')).thenAnswer(
      (_) async => const Right(
        ArtistDetail(
          artist: Artist(id: 'ar1', name: 'Arijit'),
        ),
      ),
    );

    await usecase(' ar1 ');

    verify(() => repository.artist('ar1')).called(1);
  });
}
