import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/features/artist/domain/repositories/artist_repository.dart';
import 'package:aura_music/features/artist/domain/usecases/get_artist.dart';
import 'package:aura_music/features/artist/presentation/bloc/artist_cubit.dart';
import 'package:aura_music/features/catalog/domain/entities/artist.dart';
import 'package:aura_music/features/catalog/domain/entities/artist_detail.dart';

final class _MockArtistRepository extends Mock implements ArtistRepository {}

void main() {
  late _MockArtistRepository repository;
  late ArtistCubit cubit;

  setUp(() {
    repository = _MockArtistRepository();
    cubit = ArtistCubit(GetArtist(repository));
  });

  tearDown(() => cubit.close());

  test('load emits loading then ready', () async {
    when(() => repository.artist('ar1')).thenAnswer(
      (_) async => const Right(
        ArtistDetail(
          artist: Artist(id: 'ar1', name: 'Arijit'),
        ),
      ),
    );

    expect(cubit.state.status, ArtistStatus.loading);

    await cubit.load('ar1');

    expect(cubit.state.status, ArtistStatus.ready);
    expect(cubit.state.detail!.artist.id, 'ar1');
  });

  test('load emits error on failure', () async {
    when(
      () => repository.artist('ar1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    await cubit.load('ar1');

    expect(cubit.state.status, ArtistStatus.error);
    expect(cubit.state.error, 'boom');
  });
}
