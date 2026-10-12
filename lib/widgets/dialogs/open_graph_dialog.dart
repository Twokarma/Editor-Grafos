import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../providers/graph_provider.dart';

Future<void> showOpenDialog(BuildContext context, GraphProvider provider) async {
  final names = await provider.listSavedGraphs();
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      final localNames = List<String>.from(names);
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text("Open graph"),
            content: SizedBox(
              width: double.maxFinite,
              child: localNames.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No saved graphs yet"),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: localNames.length,
                itemBuilder: (context, index) {
                  final name = localNames[index];
                  return ListTile(
                    title: Text(name),
                    onTap: () async {
                      await provider.loadGraph(name);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: "Delete",
                      onPressed: () async {
                        await provider.deleteGraph(name);
                        setDialogState(() {
                          localNames.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    },
  );
}