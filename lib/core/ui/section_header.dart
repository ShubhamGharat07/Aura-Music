import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Section header with a large editorial title and one quiet action.
///
/// The action is a text link, not a pill. On press the label settles by a
/// fraction and the arrow travels forward with it, which makes the link feel
/// connected to the section without adding chrome.
final class SectionHeader extends HookWidget {
  /// Creates a section header.
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.actionLabel = 'See all',
    this.actionIcon,
  });

  /// Section title.
  final String title;

  /// Action callback (null hides the action).
  final VoidCallback? onSeeAll;

  /// Action label.
  final String actionLabel;

  /// Optional action icon override.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final pressed = useState(false);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSeeAll != null) ...[
          SizedBox(width: AppSpacing.md),
          AnimatedScale(
            scale: pressed.value && !reduceMotion ? 0.97 : 1,
            duration: AppDurations.fast,
            curve: AppCurves.out,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onSeeAll,
                onHighlightChanged: (value) => pressed.value = value,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 10.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel,
                        style: AppTypography.caption.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: pressed.value
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      AnimatedSlide(
                        offset: pressed.value && !reduceMotion
                            ? const Offset(0.18, 0)
                            : Offset.zero,
                        duration: AppDurations.fast,
                        curve: AppCurves.out,
                        child: Icon(
                          actionIcon ?? Icons.arrow_forward_rounded,
                          size: actionIcon == null ? 15.r : 16.r,
                          color: pressed.value
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
