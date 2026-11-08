import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura_music/core/theme/colors.dart';
import 'package:aura_music/core/theme/tokens.dart';
import 'package:aura_music/core/theme/typography.dart';

/// Asks for a single line of text (create / rename a playlist).

/// Shows a text prompt dialog; resolves to the entered text or null.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String? hint,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: (_) => _TextPromptDialog(
      title: title,
      confirmLabel: confirmLabel,
      initial: initial,
      hint: hint,
    ),
  );
}

final class _TextPromptDialog extends HookWidget {
  const _TextPromptDialog({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    this.hint,
  });

  final String title;
  final String confirmLabel;
  final String initial;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initial);
    useListenable(controller);
    final renaming = initial.isNotEmpty;
    final canSubmit = controller.text.trim().isNotEmpty;

    void submit() {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      Navigator.pop(context, value);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.w),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgElevated,
                Color.lerp(AppColors.bgElevated, AppColors.bg, 0.55)!,
              ],
            ),
            border: Border.all(color: AppColors.glassBorder, width: 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 24.w, 24.w, 18.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppColors.glassBorder,
                          width: 0.7,
                        ),
                      ),
                      child: Icon(
                        renaming
                            ? Icons.edit_rounded
                            : Icons.playlist_add_rounded,
                        size: 20.r,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              fontSize: 19.sp,
                            ),
                          ),
                          SizedBox(height: 3.w),
                          Text(
                            renaming
                                ? 'Choose a new name for this playlist.'
                                : 'Give it a name. You can rename it later.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              fontSize: 12.5.sp,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22.w),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => submit(),
                  cursorColor: AppColors.textPrimary,
                  cursorWidth: 1.4,
                  style: AppTypography.body.copyWith(fontSize: 15.5.sp),
                  decoration: InputDecoration(
                    hintText: hint ?? 'Playlist name',
                    hintStyle: AppTypography.body.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.bg.withValues(alpha: 0.7),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.w,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: const BorderSide(
                        color: AppColors.glassBorder,
                        width: 0.7,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide(
                        color: AppColors.textPrimary.withValues(alpha: 0.24),
                        width: 0.9,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.w),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          minimumSize: Size(0, 46.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          textStyle: AppTypography.body.copyWith(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: canSubmit ? submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.bg,
                          disabledBackgroundColor: AppColors.textPrimary
                              .withValues(alpha: 0.08),
                          disabledForegroundColor: AppColors.textTertiary,
                          minimumSize: Size(0, 46.w),
                          shape: const StadiumBorder(),
                          textStyle: AppTypography.body.copyWith(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
