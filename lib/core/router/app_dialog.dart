import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Dialog helpers. `core/router` is the only layer allowed to touch
/// [Navigator] directly (PRD 4.3); screens call these helpers instead.

/// Pops the top-most dialog, sheet or popover (no-op when none is open).
void closeOverlay(BuildContext context) => Navigator.of(context).maybePop();

/// Shows a confirm/cancel dialog; resolves `true` when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Shows a destructive dialog that requires typing [keyword] to confirm
/// (PRD S20 "clear all data"). Resolves `true` only on an exact match.
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String keyword,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => HookBuilder(
      builder: (context) {
        final controller = useTextEditingController();
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16.w),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Type $keyword to confirm',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => FilledButton(
                onPressed: value.text.trim() == keyword
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: Text(confirmLabel),
              ),
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}
