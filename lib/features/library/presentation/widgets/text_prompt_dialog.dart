import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
