import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/error/failures.dart';
import 'package:aura_music/core/ui/aura_hero.dart';
import 'package:aura_music/features/album/domain/repositories/album_repository.dart';
import 'package:aura_music/features/album/domain/usecases/get_album.dart';
import 'package:aura_music/features/album/presentation/bloc/album_cubit.dart';
import 'package:aura_music/features/album/presentation/pages/album_page.dart';
import 'package:aura_music/features/album/presentation/widgets/album_header.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/domain/entities/album_detail.dart';

import '../../helpers/pump_app.dart';

final class _PendingAlbum implements AlbumRepository {
  final result = Completer<Either<Failure, AlbumDetail>>();

  @override
  Future<Either<Failure, AlbumDetail>> album(String id) => result.future;
}

void main() {
  testWidgets('album header keeps its hero while details are loading', (
    tester,
  ) async {
    const album = Album(id: '1', title: 'Album title', artist: 'Artist');
    const tag = ('album-card', '1');
    final repository = _PendingAlbum();
    getIt.registerFactory(() => AlbumCubit(GetAlbum(repository)));
    addTearDown(() => getIt.unregister<AlbumCubit>());

    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const AlbumPage(
                  albumId: '1',
                  initialAlbum: album,
                  heroTag: tag,
                ),
              ),
            ),
            child: const AuraHero(
              tag: tag,
              child: SizedBox(
                width: 70,
                height: 70,
                child: ColoredBox(color: Colors.teal),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AuraHero));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final headerHero = find.descendant(
      of: find.byType(AlbumHeader),
      matching: find.byType(Hero),
    );
    final element = tester.element(headerHero);
    expect(tester.widget<Hero>(headerHero).tag, tag);

    repository.result.complete(
      const Right(AlbumDetail(album: album, songs: [])),
    );
    await tester.pumpAndSettle();
    expect(tester.element(headerHero), same(element));
    expect(find.text('Songs'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
