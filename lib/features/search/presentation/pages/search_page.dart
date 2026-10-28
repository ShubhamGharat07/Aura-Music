import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/constants/app_constants.dart';
import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/hooks/use_debounced_value.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/responsive/responsive_insets.dart';
import 'package:aura_music/core/responsive/window_size_class.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/search/presentation/bloc/search_bloc.dart';
import 'package:aura_music/features/search/presentation/bloc/search_event.dart';
import 'package:aura_music/features/search/presentation/bloc/search_state.dart';
import 'package:aura_music/features/search/presentation/widgets/search_filter_bar.dart';
import 'package:aura_music/features/search/presentation/widgets/search_idle_view.dart';
import 'package:aura_music/features/search/presentation/widgets/search_results_view.dart';
import 'package:aura_music/features/search/presentation/widgets/search_suggestions_view.dart';

/// Search tab root (PRD S04/S05). A debounced query drives [SearchBloc]:
/// idle - recent/genres, typing - suggestions, submit - grouped results.

/// Search page.
final class SearchPage extends HookWidget {
  /// Creates the search page.
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final bloc = useMemoized(() => getIt<SearchBloc>(), const []);
    useEffect(() {
      bloc.add(const SearchRecentRequested());
      return () => bloc.close();
    }, [bloc]);
    // The tab is preloaded while hidden; only fetch suggestions once it is
    // actually shown so startup stays light (default TickerMode hides it).
    final visible = TickerMode.valuesOf(context).enabled;
    final browseRequested = useRef(false);
    useEffect(() {
      if (visible && !browseRequested.value) {
        browseRequested.value = true;
        bloc.add(const SearchBrowseRequested());
      }
      return null;
    }, [visible, bloc]);
    final sizeClass = WindowSizeClass.of(context);
    return BlocProvider<SearchBloc>.value(
      value: bloc,
      child: MaxContentWidth(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveInsets.side(sizeClass)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search', style: AppTypography.display),
              SizedBox(height: 6.w),
              Text(
                'Find the next thing on repeat.',
                style: AppTypography.caption.copyWith(fontSize: 14.sp),
              ),
              SizedBox(height: 22.w),
              _SearchField(controller: controller),
              SizedBox(height: 16.w),
              Expanded(
                child: _KeyboardInset(child: _Body(controller: controller)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reserves the IME's height so results stay scrollable above the keyboard. The
// shell Scaffold keeps resizeToAvoidBottomInset disabled (to pin the floating
// bar), so pages without a Scaffold of their own - this tab - inset themselves.
// The rebuild is scoped to this leaf; its child instance is reused.
final class _KeyboardInset extends StatelessWidget {
  const _KeyboardInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}

// Owns the keystroke-level rebuilds (listenable controller + debounce) so the
// results body below is not rebuilt on every character typed.
final class _SearchField extends HookWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    useListenable(controller);
    final query = useDebouncedValue(
      controller.text,
      AppConstants.searchDebounce,
    );
    useEffect(() {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
      return null;
    }, [query]);
    return SearchBar(
      controller: controller,
      hintText: 'Songs, albums, artists',
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        AppColors.bgElevated.withValues(alpha: 0.62),
      ),
      side: const WidgetStatePropertyAll(
        BorderSide(color: AppColors.glassBorder, width: 0.7),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      ),
      constraints: BoxConstraints(minHeight: 56.w),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      ),
      textStyle: WidgetStatePropertyAll(AppTypography.body),
      hintStyle: WidgetStatePropertyAll(
        AppTypography.body.copyWith(
          color: AppColors.textTertiary,
          fontSize: 14.5.sp,
        ),
      ),
      leading: Icon(
        Icons.search_rounded,
        size: 22.r,
        color: AppColors.textSecondary,
      ),
      onSubmitted: (value) =>
          context.read<SearchBloc>().add(SearchSubmitted(value)),
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final TextEditingController controller;

  void _submit(BuildContext context, String term) {
    controller.text = term;
    context.read<SearchBloc>().add(SearchSubmitted(term));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        switch (state.status) {
          case SearchStatus.idle:
            return SearchIdleView(
              recent: state.recent,
              onTermTap: (term) => _submit(context, term),
              onClearRecent: () =>
                  context.read<SearchBloc>().add(const SearchHistoryCleared()),
              onRemoveTerm: (term) =>
                  context.read<SearchBloc>().add(SearchRecentRemoved(term)),
              browse: state.browse,
              browseStatus: state.browseStatus,
              browseError: state.browseError,
              onPlay: (tracks, index) =>
                  playFromCatalog(context, tracks, index),
              onRetry: () =>
                  context.read<SearchBloc>().add(const SearchBrowseRequested()),
            );
          case SearchStatus.suggesting:
            return SearchSuggestionsView(
              suggestions: state.suggestions,
              onSelect: (term) => _submit(context, term),
            );
          case SearchStatus.loading:
            return const StateView(
              kind: StateKind.loading,
              message: 'Searching...',
            );
          case SearchStatus.error:
            return StateView(
              kind: StateKind.error,
              message: state.error ?? 'Search failed',
              onRetry: () =>
                  context.read<SearchBloc>().add(SearchSubmitted(state.query)),
            );
          case SearchStatus.ready:
            return Column(
              children: [
                SearchFilterBar(
                  selected: state.filter,
                  countFor: state.countFor,
                  onSelect: (filter) => context.read<SearchBloc>().add(
                    SearchFilterChanged(filter),
                  ),
                ),
                SizedBox(height: 12.w),
                Expanded(
                  child: SearchResultsView(
                    state: state,
                    onPlay: (tracks, index) =>
                        playFromCatalog(context, tracks, index),
                  ),
                ),
              ],
            );
        }
      },
    );
  }
}
