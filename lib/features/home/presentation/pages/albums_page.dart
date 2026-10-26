import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/adaptive_grid.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/ui/media_card.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/domain/entities/album.dart';
import 'package:aura_music/features/catalog/presentation/album_labels.dart';
import 'package:aura_music/features/home/presentation/bloc/albums_cubit.dart';

/// Album browse screen (PRD S03) behind the home grids' "See all".

/// Full album grid page.
final class AlbumsPage extends HookWidget {
  /// Creates the album grid page.
  const AlbumsPage({super.key, required this.kind});

  /// Which album list to show.
  final AlbumsKind kind;

  @override
  Widget build(BuildContext context) {
    final cubit = useMemoized(() => getIt<AlbumsCubit>(), const []);
    useEffect(() {
      cubit.load(kind);
      return () => cubit.close();
    }, [cubit, kind]);
    final sizeClass = WindowSizeClass.of(context);
    return BlocProvider<AlbumsCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(kind.title)),
        body: BlocBuilder<AlbumsCubit, AlbumsState>(
          builder: (context, state) => switch (state.status) {
            AlbumsStatus.loading => const StateView(
              kind: StateKind.loading,
              message: 'Loading albums…',
            ),
            AlbumsStatus.error => StateView(
              kind: StateKind.error,
              message: state.error ?? 'Failed to load albums',
              onRetry: () => cubit.load(kind),
            ),
            AlbumsStatus.empty => const StateView(
              kind: StateKind.empty,
              message: 'No albums right now',
            ),
            AlbumsStatus.ready => _Grid(
              albums: state.albums,
              inset: ResponsiveInsets.side(sizeClass),
            ),
          },
        ),
      ),
    );
  }
}

final class _Grid extends StatelessWidget {
  const _Grid({required this.albums, required this.inset});

  final List<Album> albums;
  final double inset;

  @override
  Widget build(BuildContext context) {
    return MaxContentWidth(
      child: CustomScrollView(
        slivers: [
          SliverLayoutBuilder(
            builder: (context, constraints) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                inset,
                inset,
                inset,
                inset + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverGrid(
                gridDelegate: AdaptiveGrid.delegate(
                  availableWidth: constraints.crossAxisExtent - inset * 2,
                  targetCardWidth: 150,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => MediaCard(
                    title: albums[i].title,
                    subtitle: albums[i].cardSubtitle,
                    artUrl: albums[i].artUrl,
                    onTap: () =>
                        context.push('${AppRoutes.album}/${albums[i].id}'),
                  ),
                  childCount: albums.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
