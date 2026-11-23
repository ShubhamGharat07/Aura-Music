import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_music/core/router/routes.dart';
import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/section_header.dart';
import 'package:aura_music/core/ui/skeleton.dart';
import 'package:aura_music/features/catalog/domain/entities/playlist.dart';
import 'package:aura_music/features/home/presentation/bloc/home_state.dart';

/// "Time Machine" carousel (PRD S03): the chart playlists grouped by decade.
///
/// The decade rows already live in the charts payload (`Hindi 90s`,
/// `Hindi 2000s`, …), so this section is derived locally and costs no extra
/// network call. It hides itself unless at least two decades are available.
final class HomeTimeMachine extends StatelessWidget {
  /// Creates the time machine section.
  const HomeTimeMachine({
    super.key,
    required this.section,
    required this.padding,
    this.cardWidth = 132,
    this.onRetry,
  });

  /// Chart section (its playlists are mined for decade titles).
  final PlaylistSection section;

  /// Horizontal inset from the window class.
  final double padding;

  /// Card width (also its height).
  final double cardWidth;

  /// Retry callback for the error state.
  final VoidCallback? onRetry;

  static final RegExp _fullDecade = RegExp(
    r'\b(?:19|20)\d0s\b',
    caseSensitive: false,
  );
  static final RegExp _shortDecade = RegExp(
    r'\b\d0s\b',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final decades = _decades();
    if (section.status == SectionStatus.empty ||
        (section.status == SectionStatus.ready && decades.length < 2)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.lg,
            padding,
            AppSpacing.xs,
          ),
          child: const SectionHeader(title: 'Time Machine'),
        ),
        SizedBox(
          height: cardWidth,
          child: switch (section.status) {
            SectionStatus.loading => _loading(),
            SectionStatus.error => _error(),
            _ => _list(decades),
          },
        ),
      ],
    );
  }

  List<({String label, Playlist playlist})> _decades() {
    final seen = <String>{};
    final decades = <({String label, Playlist playlist})>[];
    for (final playlist in section.playlists) {
      final label = _decadeLabel(playlist.title);
      if (label == null || !seen.add(label)) continue;
      decades.add((label: label, playlist: playlist));
    }
    decades.sort(
      (a, b) => _decadeValue(a.label).compareTo(_decadeValue(b.label)),
    );
    return decades;
  }

  Widget _list(List<({String label, Playlist playlist})> decades) =>
      ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        physics: const BouncingScrollPhysics(),
        itemCount: decades.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (_, i) => _DecadeCard(
          label: decades[i].label,
          playlist: decades[i].playlist,
          width: cardWidth,
        ),
      );

  Widget _loading() => Shimmer(
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: 4,
      separatorBuilder: (_, _) => SizedBox(width: 12.w),
      itemBuilder: (_, _) => Skeleton(
        width: cardWidth,
        height: cardWidth,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
  );

  Widget _error() => Padding(
    padding: EdgeInsets.fromLTRB(padding, 4.w, padding, 4.w),
    child: Row(
      children: [
        Expanded(
          child: Text(
            section.error ?? 'Could not load',
            style: AppTypography.caption,
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );

  static String? _decadeLabel(String title) {
    final match =
        _fullDecade.firstMatch(title) ?? _shortDecade.firstMatch(title);
    if (match == null) return null;
    return match.group(0)?.toLowerCase();
  }

  static int _decadeValue(String label) {
    final digits = int.tryParse(label.replaceAll('s', '')) ?? 0;
    return digits < 100 ? 1900 + digits : digits;
  }
}

final class _DecadeCard extends HookWidget {
  const _DecadeCard({
    required this.label,
    required this.playlist,
    required this.width,
  });

  final String label;
  final Playlist playlist;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = BorderRadius.circular(AppRadius.card);
    return SizedBox(
      width: width,
      height: width,
      child: AnimatedScale(
        scale: pressed.value && !reduceMotion ? 0.975 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.out,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('${AppRoutes.playlist}/${playlist.id}');
            },
            onHighlightChanged: (value) => pressed.value = value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _art(radius),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.30, 1],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.74),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 9.w,
                  left: 9.w,
                  child: Icon(
                    Icons.history_rounded,
                    size: 15.r,
                    color: Colors.white70,
                  ),
                ),
                Positioned(
                  left: 11.w,
                  right: 11.w,
                  bottom: 9.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display.copyWith(
                          fontSize: 26.sp,
                          height: 1,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 3.w),
                      Text(
                        playlist.subtitle?.isNotEmpty == true
                            ? playlist.subtitle!
                            : 'Time travel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _art(BorderRadius radius) {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Center(
        child: Icon(
          Icons.history_toggle_off_rounded,
          size: 26.r,
          color: AppColors.textTertiary,
        ),
      ),
    );
    final url = playlist.artUrl;
    if (url == null) {
      return ClipRRect(borderRadius: radius, child: fallback);
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 300,
        memCacheHeight: 300,
        fadeInDuration: AppDurations.fast,
        fadeInCurve: AppCurves.out,
        placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
