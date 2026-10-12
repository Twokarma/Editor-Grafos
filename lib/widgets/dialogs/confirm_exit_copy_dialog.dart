import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';

enum ExitOption {discard, apply, cancel}

Future<void> showConfirmExitCopyDialog(
    BuildContext context,
    GraphProvider mainProvider,
    GraphProvider copy
    ) async {
  final ExitOption? option = await showDialog<ExitOption>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Unapplied changes"),
          content: const Text("Apply changes to the main Graph?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.discard),
              child: const Text("Discard"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.cancel),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.apply),
              child: const Text("Apply & Exit"),
            ),
          ],
        );
      }
  );

  if(option == null || !context.mounted) return;

  switch(option){
    case ExitOption.discard :
      Navigator.of(context).pop();
      break;
    case ExitOption.apply :
      mainProvider.replaceGraph(copy.snapshot());
      Navigator.of(context).pop();
      break;
    case ExitOption.cancel :
      break;
  }
}