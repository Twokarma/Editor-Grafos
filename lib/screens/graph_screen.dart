import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/screens/insertion_sort.dart';

import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:provider/provider.dart';

import '../providers/graph_provider.dart';
import 'chat_screen.dart';
import 'hungarian_screen.dart';
import 'matrix_screen.dart';
import 'selection_sort.dart';
import 'JohnsonScreen .dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  Future<void> _showSortMenu(BuildContext fabContext) async {
  const menuWidth = 200.0;

  final button = fabContext.findRenderObject() as RenderBox;
  final overlay =
  Overlay.of(fabContext).context.findRenderObject() as RenderBox;

  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);

  // El borde derecho del menú queda justo a la izquierda del botón
  final position = RelativeRect.fromLTRB(
    topLeft.dx - menuWidth - 8,
    topLeft.dy,
    overlay.size.width - topLeft.dx + 8,
    overlay.size.height - topLeft.dy - button.size.height,
  );

  final value = await showMenu<String>(
    context: fabContext,
    position: position,
    elevation: 2,
    color: Colors.blueGrey[60],
    constraints: const BoxConstraints.tightFor(width: menuWidth),
    items: const [
      PopupMenuItem(
        value: 'selection',
        child: ListTile(
          leading: Icon(Icons.sort),
          title: Text("Selection Sort"),
          iconColor: Colors.blueAccent,
        ),
      ),
      PopupMenuItem(
        value: 'insertion',
        child: ListTile(
          leading: Icon(Icons.more_horiz),
          title: Text("Insertion sort"),
          iconColor: Colors.blueAccent,
        ),
      ),
      // PopupMenuItem(value: 'otro', child: ...),
    ],
  );

 if (value == null || !fabContext.mounted) return;
  switch( value){
    case 'selection':
      Navigator.of(fabContext).push(
        MaterialPageRoute(builder: (_) => const SelectionSort()),
      );
      break;
    case 'insertion':
      Navigator.of(fabContext).push(
        MaterialPageRoute(builder: (_) => const InsertionSort()),
      );
      break;
  }
}



  Future<void> _showSaveDialog(BuildContext context, GraphProvider provider) async {
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

  Future<void> _showOpenDialog(BuildContext context, GraphProvider provider) async {
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

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Graph Maker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Undo",
            onPressed: graphProvider.canUndo ? () => graphProvider.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear graph",
            onPressed: () => graphProvider.clearGraph(),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: "Save graph",
            onPressed: () => _showSaveDialog(context, graphProvider),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: "Open graph",
            onPressed: () => _showOpenDialog(context, graphProvider),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: "AI Assistant",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ],
      ),
      body: GraphWidget(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "hungarianFab",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HungarianScreen()),
              );
            },
            shape: const CircleBorder(),
            child: const Text(
              "🇭🇺",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "matrixFab",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MatrixScreen()),
              );
            },
            shape: const CircleBorder(),
            child: const Text(
              "M[x]",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "johnsonFab",
            onPressed: () {
              final graph = graphProvider.graphGetter();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JohnsonScreen(
                    labels: graph.johnsonLabels(),
                    edges: graph.johnsonEdges(),
                    cpmEdges: graph.cpmEdges(),
                  ),
                ),
              );
            },
            shape: const CircleBorder(),
            child: const Text(
              "J",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),

         
           const SizedBox(height: 12),
          Builder(
            builder: (fabContext) => FloatingActionButton(
              heroTag: "menuFab",
              onPressed: () => _showSortMenu(fabContext),
              shape: const CircleBorder(),
              child: const Icon(Icons.more_horiz),
            ),
          ),
        ],
      ),
    );
  }
}