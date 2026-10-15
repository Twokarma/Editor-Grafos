import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/rules/assignment_rules.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/rules/johnson_rules.dart';
import 'package:graph_maker_app_2/screens/assignment_screen.dart';
import 'package:graph_maker_app_2/screens/johnson_screen.dart';
import 'package:graph_maker_app_2/screens/selection_sort.dart';

import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:provider/provider.dart';

import '../providers/graph_provider.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import 'chat_screen.dart';
import 'insertion_sort.dart';
import 'matrix_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();

    GraphProvider Function(BuildContext) createProvider(GraphRules rules) {
      return (BuildContext context) => GraphProvider(initialGraph: graphProvider.snapshot(), graphRules: rules);
    }

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
            onPressed: () => showSaveDialog(context, graphProvider),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: "Open graph",
            onPressed: () => showOpenDialog(context, graphProvider),
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChangeNotifierProvider<GraphProvider>(
                  create: createProvider(JohnsonRules())  ,
                  child: JohnsonScreen(mainProvider: graphProvider),
                )
                ),
              );
            },
            heroTag: 'johnson',
            shape: const CircleBorder(),
            child: const Text(
              "J",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),

          SizedBox(height: 17,),

          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChangeNotifierProvider<GraphProvider>(
                    create: createProvider(AssignmentRules())  ,
                    child: AssignmentScreen(mainProvider: graphProvider),
                )
                ),
              );
            },
            heroTag: 'hungarian',
            shape: const CircleBorder(),
            child: const Text(
              "🇭🇺",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),

          SizedBox(height: 17,),

          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MatrixScreen()),
              );
            },
            heroTag: 'main_matrix',
            shape: const CircleBorder(),
            child: const Text(
              "M[x]",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
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
