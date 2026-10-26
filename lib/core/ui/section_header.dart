import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Section header with title + optional "See all" action (PRD S03).

/// Section header row.
final class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  /// Section title.
  final String title;

  /// "See all" callback (null hides the button).
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
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
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: AppTypography.caption.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.chevron_right_rounded, size: 16.r, color: accent),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
