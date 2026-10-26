import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/features/search/domain/entities/search_results.dart';
import 'package:aura_music/features/search/domain/repositories/search_repository.dart';
import 'package:aura_music/features/search/domain/usecases/search_catalog.dart';

final class _MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late _MockSearchRepository repository;
  late SearchCatalog usecase;

  setUp(() {
    repository = _MockSearchRepository();
    usecase = SearchCatalog(repository);
  });

  test(
    'blank query short-circuits to empty results without asking the repo',
    () async {
      final result = await usecase('   ');

      expect(result.getOrElse((_) => const SearchResults()).isEmpty, isTrue);
      verifyNever(() => repository.search(any()));
    },
  );

  test('delegates a trimmed query to the repository', () async {
    when(
      () => repository.search('neon'),
    ).thenAnswer((_) async => const Right(SearchResults()));

    await usecase('  neon ');

    verify(() => repository.search('neon')).called(1);
  });
}
