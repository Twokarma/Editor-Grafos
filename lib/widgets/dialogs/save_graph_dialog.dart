import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../providers/graph_provider.dart';

Future<void> showSaveDialog(BuildContext context, GraphProvider provider) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Save graph"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Graph name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      );
    },
  );

  if (name == null || name.isEmpty) return;
  if (!context.mounted) return;

  final exists = await provider.savedGraphExists(name);
  if (!context.mounted) return;

  if (exists) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Replace existing save?"),
          content: Text('A saved graph named "$name" already exists. Replace it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Replace"),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
  }

  await provider.saveGraph(name);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Saved as "$name"')),
  );
}