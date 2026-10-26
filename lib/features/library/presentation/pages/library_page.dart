import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/two_pane.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/features/library/presentation/bloc/library_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/liked_tracks_cubit.dart';
import 'package:aura_music/features/library/presentation/bloc/playlists_cubit.dart';
import 'package:aura_music/features/library/presentation/widgets/library_collections.dart';
import 'package:aura_music/features/library/presentation/widgets/library_sections.dart';
import 'package:aura_music/features/library/presentation/widgets/library_shortcuts.dart';

/// Library (PRD S12). Shortcut tiles + collections (chips/grid/sort) + liked
/// and discover feeds. Compact/medium: stacked. Expanded: master-detail.

/// Library tab root.
final class LibraryPage extends StatelessWidget {
  /// Creates the library page.
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sizeClass = WindowSizeClass.of(context);
    final pad = ResponsiveInsets.side(sizeClass);
    return MultiBlocProvider(
      providers: [
        BlocProvider<LibraryCubit>(
          create: (_) => getIt<LibraryCubit>()..load(),
        ),
        BlocProvider<LikedTracksCubit>(
          create: (_) => getIt<LikedTracksCubit>()..load(),
        ),
        BlocProvider<PlaylistsCubit>(
          create: (_) => getIt<PlaylistsCubit>()..load(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: MaxContentWidth(
          child: sizeClass.isExpandedUp
              ? Padding(
                  padding: EdgeInsets.all(pad),
                  child: TwoPane(master: _MasterPane(), detail: _DetailPane()),
                )
              : _buildSections(context),
        ),
      ),
    );
  }

  Widget _buildSections(BuildContext context) {
    final pad = ResponsiveInsets.side(WindowSizeClass.of(context));
    final sections = <Widget>[
      LibraryOverview(),
      SizedBox(height: 16.w),
      LibraryShortcuts(),
      SizedBox(height: 20.w),
      LibraryCollections(selectMode: false),
      SizedBox(height: 20.w),
      LikedSection(scrollable: false, limit: 4),
      SizedBox(height: 20.w),
      DiscoverSection(scrollable: false, limit: 5),
      SizedBox(height: 8.w),
    ];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        pad,
        8.w,
        pad,
        MediaQuery.paddingOf(context).bottom + 16.w,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) => sections[index],
    );
  }
}

final class _MasterPane extends StatelessWidget {
  const _MasterPane();

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      LibraryShortcuts(),
      SizedBox(height: 16.w),
      LibraryCollections(selectMode: true),
    ];
    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16.w,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) => sections[index],
    );
  }
}

final class _DetailPane extends StatelessWidget {
  const _DetailPane();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, library) =>
          BlocBuilder<LikedTracksCubit, LikedTracksState>(
            builder: (context, liked) =>
                BlocBuilder<PlaylistsCubit, PlaylistsState>(
                  builder: (context, playlists) {
                    LibraryCollection? selected;
                    if (library.selectedId != null) {
                      final rows = buildLibraryCollections(
                        library: library,
                        liked: liked.tracks,
                        playlists: playlists.playlists,
                      );
                      for (final row in rows) {
                        if (row.id == library.selectedId) {
                          selected = row;
                          break;
                        }
                      }
                    }
                    if (selected == null || selected.isPlaylist) {
                      return const LikedSection(scrollable: true);
                    }
                    return CollectionDetail(collection: selected);
                  },
                ),
          ),
    );
  }
}
