import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/widgets/dialogs/save_graph_dialog.dart';

enum ExitOption {save, dontSave, cancel}

Future<void> showConfirmExitDialog(
    BuildContext context,
    GraphProvider copy
    ) async {
  final ExitOption? option = await showDialog<ExitOption>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Unsaved graph"),
          content: const Text("Save graph?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.save),
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.dontSave),
              child: const Text("Don't save"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.cancel),
              child: const Text("Cancel"),
            ),
          ],
        );
      }
  );

  if(option == null || !context.mounted) return;

  switch(option){
    case ExitOption.dontSave :
      Navigator.of(context).pop();
      break;
    case ExitOption.save :
      if(await showSaveDialog(context, copy)) {
        Navigator.of(context).pop();
      }
      break;
    case ExitOption.cancel :
      break;
  }
}