import 'package:flutter_test/flutter_test.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/catalog/data/datasources/jiosaavn_remote_data_source.dart';
import 'package:aura_music/features/catalog/data/repositories/catalog_repository_impl.dart';

import '../../helpers/fake_dio.dart';

void main() {
  const baseUrl = 'https://www.jiosaavn.com';

  Map<String, dynamic> payload() => {
    'results': [
      {'id': '1', 'title': 'A', 'more_info': <String, dynamic>{}},
    ],
  };

  CatalogRepositoryImpl repoWith(FakeHttpAdapter adapter) =>
      CatalogRepositoryImpl(
        JiosaavnRemoteDataSource(dioWithAdapter(adapter, baseUrl: baseUrl)),
      );

  test('returns Right with tracks on success', () async {
    final repo = repoWith(
      FakeHttpAdapter((_) async => jsonResponse(payload())),
    );

    final result = await repo.trending();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => const []), hasLength(1));
  });

  test('maps network failure to NetworkFailure', () async {
    final repo = repoWith(
      FakeHttpAdapter((_) async => throw Exception('offline')),
    );

    final result = await repo.trending();

    expect(result.isLeft(), isTrue);
    result.match(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('maps server failure to ServerFailure', () async {
    final repo = repoWith(
      FakeHttpAdapter((_) async => jsonResponse({'e': 1}, status: 500)),
    );

    final result = await repo.trending();

    result.match(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
