import 'package:flutter/material.dart';
import 'package:mascot_studio/ui/theme.dart';

Future<bool> showStudioConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: StudioColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioRadii.card),
          side: const BorderSide(color: StudioColors.border),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          body,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: StudioColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
