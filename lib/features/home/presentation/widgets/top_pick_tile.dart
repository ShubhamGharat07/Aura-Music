import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/features/player/domain/entities/track.dart';

/// One artwork tile in the Home Top Picks pager.
final class TopPickTile extends HookWidget {
  const TopPickTile({
    super.key,
    required this.track,
    required this.titleBlock,
    required this.artistBlock,
    required this.onTap,
  });

  final Track track;
  final double titleBlock;
  final double artistBlock;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedScale(
      scale: pressed.value && !reduceMotion ? 0.975 : 1,
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: AppCurves.out,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (value) => pressed.value = value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: _art(),
                ),
              ),
              SizedBox(height: 9.h),
              SizedBox(
                height: titleBlock,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    track.title,
                    style: AppTypography.subtitle.copyWith(
                      fontSize: 14.5.sp,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              SizedBox(
                height: artistBlock,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    track.artist,
                    style: AppTypography.caption.copyWith(fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _art() {
    final fallback = ColoredBox(
      color: AppColors.bgElevated,
      child: Icon(
        Icons.music_note_rounded,
        size: 22.r,
        color: AppColors.textTertiary,
      ),
    );
    final url = track.artUrl;
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      memCacheWidth: 300,
      memCacheHeight: 300,
      fit: BoxFit.cover,
      fadeInDuration: AppDurations.fast,
      placeholder: (_, _) => const ColoredBox(color: AppColors.bgElevated),
      errorWidget: (_, _, _) => fallback,
    );
  }
}
