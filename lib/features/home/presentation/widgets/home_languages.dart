import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';
import 'package:aura_music/core/ui/glass_sheet.dart';
import 'package:aura_music/features/catalog/domain/entities/catalog_language.dart';

/// Browse header + language picker (PRD S03).
///
/// Language used to be a chip rail at the very bottom of the feed, after every
/// playlist and album — effectively invisible. It now lives beside the Browse
/// title as a compact control and opens a sheet, so the feed keeps one primary
/// mood rail instead of two competing rows of pills.

/// Browse header with language selector.
final class HomeLanguages extends StatelessWidget {
  /// Creates the browse header.
  const HomeLanguages({
    super.key,
    required this.padding,
    required this.languages,
    required this.selected,
    required this.onSelect,
  });

  /// Horizontal inset from the window class.
  final double padding;

  /// Languages offered by the catalog.
  final List<CatalogLanguage> languages;

  /// Currently selected language (null = all languages).
  final CatalogLanguage? selected;

  /// Fired with the tapped language (null clears the language filter).
  final ValueChanged<CatalogLanguage?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        AppSpacing.xxl,
        padding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text('Browse', style: AppTypography.title),
          const Spacer(),
          _LanguageButton(
            label: selected?.name ?? 'Language',
            active: selected != null,
            onTap: () => _openPicker(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) {
    return GlassSheet.show<void>(
      context,
      (sheetContext) => _LanguageSheet(
        languages: languages,
        selected: selected,
        onSelect: (language) {
          Navigator.of(sheetContext).pop();
          onSelect(language);
        },
      ),
    );
  }
}

final class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: active
              ? accent.withValues(alpha: 0.34)
              : AppColors.glassBorder,
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(13.w, 8.w, 10.w, 8.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                size: 17.r,
                color: active ? accent : AppColors.textSecondary,
              ),
              SizedBox(width: 6.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 120.w),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.expand_more_rounded,
                size: 17.r,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.languages,
    required this.selected,
    required this.onSelect,
  });

  final List<CatalogLanguage> languages;
  final CatalogLanguage? selected;
  final ValueChanged<CatalogLanguage?> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = <_LanguageOption>[
      const _LanguageOption(label: 'All languages'),
      for (final language in languages)
        _LanguageOption(label: language.name, language: language),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language', style: AppTypography.title),
        SizedBox(height: 4.w),
        Text(
          'Pick a language to shape this feed.',
          style: AppTypography.caption,
        ),
        SizedBox(height: 14.w),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.55,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6.w,
              crossAxisSpacing: 6.w,
              mainAxisExtent: 42.w,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.language == null
                  ? selected == null
                  : option.language!.code == selected?.code;
              return _OptionTile(
                label: option.label,
                selected: isSelected,
                onTap: () => onSelect(option.language),
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _LanguageOption {
  const _LanguageOption({required this.label, this.language});

  final String label;
  final CatalogLanguage? language;
}

final class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.11)
          : Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: selected
              ? accent.withValues(alpha: 0.28)
              : AppColors.glassBorder,
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              if (selected) ...[
                SizedBox(width: 3.w),
                Icon(Icons.check_rounded, size: 14.r, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
