import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/di/injection.dart';
import 'package:aura_music/core/responsive/max_content_width.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/aura_loader.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/core/ui/state_view.dart';
import 'package:aura_music/core/utils/formatters.dart';
import 'package:aura_music/features/catalog/presentation/catalog_playback.dart';
import 'package:aura_music/features/home/presentation/bloc/home_bloc.dart';
import 'package:aura_music/features/home/presentation/bloc/home_event.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// Every track behind Home's Top picks.
final class TopPicksPage extends StatelessWidget {
  /// Creates the page.
  const TopPicksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => getIt<HomeBloc>()..add(const HomeTopPicksStarted()),
      child: const _TopPicksView(),
    );
  }
}

final class _TopPicksView extends HookWidget {
  const _TopPicksView();

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: MaxContentWidth(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 6.h),
                child: const _TopBar(),
              ),
              Expanded(
                child: BlocBuilder<HomeBloc, HomeState>(
                  buildWhen: (previous, current) =>
                      previous.trending != current.trending,
                  builder: (context, state) {
                    final section = state.trending;
                    return switch (section.status) {
                      SectionStatus.loading => const _TopPicksLoading(),
                      SectionStatus.error || SectionStatus.empty => StateView(
                        kind: state.offline
                            ? StateKind.offline
                            : SectionStatus.empty == section.status
                            ? StateKind.empty
                            : StateKind.error,
                        message: section.error ?? 'No picks yet.',
                        onRetry: () => context.read<HomeBloc>().add(
                          const HomeTopPicksStarted(),
                        ),
                      ),
                      SectionStatus.ready => _TopPicksChart(
                        tracks: section.tracks,
                        reduceMotion: reduceMotion,
                      ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              label: 'Back',
              onTap: () {
                HapticFeedback.selectionClick();
                if (context.canPop()) context.pop();
              },
            ),
          ),
          ExcludeSemantics(
            child: Text(
              'AURA MUSIC',
              style: AppTypography.overline.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9.5.sp,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

final class _RoundButton extends HookWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Tooltip(
      message: label,
      child: AnimatedScale(
        scale: pressed.value && !reduceMotion ? 0.92 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.out,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.glassBorder, width: 0.7),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onHighlightChanged: (value) => pressed.value = value,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.out,
              width: 40.w,
              height: 40.w,
              color: pressed.value
                  ? AppColors.textPrimary.withValues(alpha: 0.07)
                  : AppColors.bgElevated.withValues(alpha: 0.55),
              child: Icon(
                icon,
                size: 16.r,
                color: pressed.value
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TopPicksChart extends StatelessWidget {
  const _TopPicksChart({required this.tracks, required this.reduceMotion});

  final List<Track> tracks;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final featured = tracks.first;
    final rest = tracks.skip(1).toList(growable: false);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
            child: _Header(
              featured: featured,
              total: tracks.length,
              reduceMotion: reduceMotion,
              onPlayAll: () {
                HapticFeedback.mediumImpact();
                playFromCatalog(context, tracks, 0);
              },
            ),
          ),
        ),
        if (rest.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 0),
            sliver: SliverList.builder(
              itemCount: rest.length,
              itemBuilder: (context, index) {
                final track = rest[index];
                return _ChartRow(
                  track: track,
                  rank: index + 2,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    playFromCatalog(context, tracks, index + 1);
                  },
                );
              },
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 36.w),
        ),
      ],
    );
  }
}

final class _Header extends HookWidget {
  const _Header({
    required this.featured,
    required this.total,
    required this.reduceMotion,
    required this.onPlayAll,
  });

  final Track featured;
  final int total;
  final bool reduceMotion;
  final VoidCallback onPlayAll;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top picks',
          style: AppTypography.display.copyWith(fontSize: 34.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 7.h),
        Text(
          'The songs on repeat, gathered in one place.',
          style: AppTypography.caption.copyWith(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 24.h),
        _FeaturePick(track: featured, reduceMotion: reduceMotion),
        SizedBox(height: 20.h),
        _PlayAllButton(
          total: total,
          reduceMotion: reduceMotion,
          onTap: onPlayAll,
        ),
        if (total > 1) ...[
          SizedBox(height: 30.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Up next',
                  style: AppTypography.title.copyWith(fontSize: 18.sp),
                ),
              ),
              Text(
                '${total - 1} more',
                style: AppTypography.overline.copyWith(
                  fontSize: 9.5.sp,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
        ],
      ],
    );
    if (reduceMotion) return content;
    return content
        .animate()
        .fadeIn(duration: 280.ms, curve: AppCurves.out)
        .slideY(begin: 0.018, end: 0, duration: 340.ms, curve: AppCurves.out);
  }
}

final class _FeaturePick extends HookWidget {
  const _FeaturePick({required this.track, required this.reduceMotion});

  final Track track;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.38).clamp(104.0, 150.0);
        return AnimatedScale(
          scale: pressed.value && !reduceMotion ? 0.985 : 1,
          duration: AppDurations.fast,
          curve: AppCurves.out,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                playFromCatalog(context, [track], 0);
              },
              onHighlightChanged: (value) => pressed.value = value,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeroMode(
                    enabled: !reduceMotion,
                    child: Hero(
                      tag: 'top-pick-featured',
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: _Cover(track: track, size: size),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NO. 1',
                            style: AppTypography.overline.copyWith(
                              fontSize: 9.5.sp,
                              letterSpacing: 1.8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Text(
                            track.title,
                            style: AppTypography.title.copyWith(
                              fontSize: 18.5.sp,
                              height: 1.18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            track.artist,
                            style: AppTypography.caption.copyWith(
                              fontSize: 12.5.sp,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _PlayAllButton extends HookWidget {
  const _PlayAllButton({
    required this.total,
    required this.reduceMotion,
    required this.onTap,
  });

  final int total;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.985 : 1,
      duration: AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => pressed.value = value,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.out,
            height: 50.h,
            width: double.infinity,
            color: pressed.value
                ? AppColors.textPrimary.withValues(alpha: 0.86)
                : AppColors.textPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 21,
                  color: AppColors.bg,
                ),
                SizedBox(width: 7.w),
                Text(
                  'Play all',
                  style: AppTypography.body.copyWith(
                    color: AppColors.bg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5.sp,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '$total songs',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bg.withValues(alpha: 0.55),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _ChartRow extends HookWidget {
  const _ChartRow({
    required this.track,
    required this.rank,
    required this.onTap,
  });

  final Track track;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final duration = track.duration;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x0AFFFFFF), width: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => pressed.value = value,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.out,
            color: pressed.value
                ? AppColors.textPrimary.withValues(alpha: 0.035)
                : Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 9.h),
            child: Row(
              children: [
                SizedBox(
                  width: 27.w,
                  child: Text(
                    rank.toString().padLeft(2, '0'),
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  width: 46.w,
                  height: 46.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: _Cover(track: track, size: 46.w),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppTypography.subtitle.copyWith(
                          fontSize: 14.5.sp,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        track.artist,
                        style: AppTypography.caption.copyWith(fontSize: 12.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (duration > Duration.zero) ...[
                  SizedBox(width: 10.w),
                  Text(
                    formatDuration(duration),
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Cover extends StatelessWidget {
  const _Cover({required this.track, required this.size});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.28,
        color: AppColors.textTertiary,
      ),
    );
    final url = track.artUrl;
    if (url == null) return fallback;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: pixels,
      memCacheHeight: pixels,
      fit: BoxFit.cover,
      fadeInDuration: AppDurations.fast,
      placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

final class _TopPicksLoading extends StatelessWidget {
  const _TopPicksLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: AuraLoader(label: 'Reading the chart')),
          SizedBox(height: 34.h),
          Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(
                  width: 180.w,
                  height: 30.h,
                  borderRadius: BorderRadius.circular(6),
                ),
                SizedBox(height: 12.h),
                Skeleton(
                  width: 245.w,
                  height: 10.h,
                  borderRadius: BorderRadius.circular(3),
                ),
                SizedBox(height: 26.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(
                      width: 128.w,
                      height: 128.w,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(
                            width: 44.w,
                            height: 8.h,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          SizedBox(height: 12.h),
                          Skeleton(
                            height: 17.h,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          SizedBox(height: 7.h),
                          Skeleton(
                            width: 130.w,
                            height: 14.h,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                Skeleton(
                  height: 50.h,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                SizedBox(height: 30.h),
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Row(
                      children: [
                        Skeleton(
                          width: 20.w,
                          height: 8.h,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        SizedBox(width: 12.w),
                        Skeleton(
                          width: 46.w,
                          height: 46.w,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(
                                height: 10.h,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(3),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Skeleton(
                                width: 110,
                                height: 8.h,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
