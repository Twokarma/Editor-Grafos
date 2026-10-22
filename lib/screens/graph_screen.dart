import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/rules/assignment_rules.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/rules/johnson_rules.dart';
import 'package:graph_maker_app_2/screens/assignment_screen.dart';
import 'package:graph_maker_app_2/screens/johnson_screen.dart';
import 'package:graph_maker_app_2/screens/merge_sort.dart';
import 'package:graph_maker_app_2/screens/selection_sort.dart';
import 'package:graph_maker_app_2/screens/shell_sort.dart';

import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../providers/graph_provider.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_tour.dart';
import 'chat_screen.dart';
import 'insertion_sort.dart';
import 'matrix_screen.dart';
import 'pdf_viewer_screen.dart'; // ★ MANUAL: openManual()

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final _undoKey = GlobalKey();
  final _clearKey = GlobalKey();
  final _saveKey = GlobalKey();
  final _openKey = GlobalKey();
  final _chatKey = GlobalKey();
  final _helpKey = GlobalKey();
  final _manualKey = GlobalKey(); // ★ MANUAL
  final _johnsonKey = GlobalKey();
  final _hungarianKey = GlobalKey();
  final _matrixKey = GlobalKey();
  final _menuKey = GlobalKey();

  void _startTour() {
    GraphTour.show(context, [
      TourStep(_undoKey, 'Deshacer',
          'Revierte la última acción realizada en el editor.'),
      TourStep(_clearKey, 'Limpiar grafo',
          'Elimina todo el contenido del grafo actual.'),
      TourStep(_saveKey, 'Guardar', 'Guarda el grafo para usarlo después.'),
      TourStep(_openKey, 'Abrir', 'Carga un grafo guardado previamente.'),
      TourStep(_chatKey, 'Asistente IA', 'Abre el chat con el asistente.'),
      // ★ MANUAL
      TourStep(_manualKey, 'Manual', 'Abre la guía rápida de la aplicación.'),
      TourStep(
        _johnsonKey,
        'Johnson (J)',
        'Calcula caminos mínimos entre pares de vértices.',
        align: ContentAlign.left,
      ),
      TourStep(
        _hungarianKey,
        'Húngaro',
        'Resuelve el problema de asignación con el algoritmo húngaro.',
        align: ContentAlign.left,
      ),
      TourStep(
        _matrixKey,
        'Matriz M[x]',
        'Abre la vista matricial del grafo.',
        align: ContentAlign.left,
      ),
      TourStep(
        _menuKey,
        'Ordenamientos',
        'Muestra Selection, Insertion, Shell y Merge Sort.',
        align: ContentAlign.left,
      ),
    ]);
  }

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
      color: Colors.blueGrey[50],
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
        PopupMenuItem(
          value: 'shell',
          child: ListTile(
            leading: Icon(Icons.more_horiz_rounded),
            title: Text("Shell sort"),
            iconColor: Colors.blueAccent,
          ),
        ),
        PopupMenuItem(
          value: 'merge',
          child: ListTile(
            leading: Icon(Icons.more_horiz_outlined),
            title: Text("Merge sort"),
            iconColor: Colors.blueAccent,
          ),
        ),
      ],
    );

    if (value == null || !fabContext.mounted) return;
    switch (value) {
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
      case 'shell':
        Navigator.of(fabContext).push(
          MaterialPageRoute(builder: (_) => const ShellSort()),
        );
        break;
      case 'merge':
        Navigator.of(fabContext).push(
          MaterialPageRoute(builder: (_) => const MergeSort()),
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
            key: _undoKey,
            icon: const Icon(Icons.undo),
            tooltip: "Undo",
            onPressed:
                graphProvider.canUndo ? () => graphProvider.undo() : null,
          ),
          IconButton(
            key: _clearKey,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Clear graph",
            onPressed: () => graphProvider.clearGraph(),
          ),
          IconButton(
            key: _saveKey,
            icon: const Icon(Icons.save_outlined),
            tooltip: "Save graph",
            onPressed: () => showSaveDialog(context, graphProvider),
          ),
          IconButton(
            key: _openKey,
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: "Open graph",
            onPressed: () => showOpenDialog(context, graphProvider),
          ),
          IconButton(
            key: _chatKey,
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: "AI Assistant",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
          // ★ MANUAL: abre graph_maker_guia_rapida.pdf
          IconButton(
            key: _manualKey,
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: "Manual",
            onPressed: () => openManual(
              context,
              title: 'Graph Maker',
              assetPath: 'assets/docs/guia_graph_maker.pdf',
            ),
          ),
          IconButton(
            key: _helpKey,
            icon: const Icon(Icons.help_outline),
            tooltip: "Help",
            onPressed: _startTour,
          ),
        ],
      ),
      body: GraphWidget(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            key: _johnsonKey,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<GraphProvider>(
                    create: createProvider(JohnsonRules()),
                    child: JohnsonScreen(mainProvider: graphProvider),
                  ),
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
          const SizedBox(height: 17),
          FloatingActionButton(
            key: _hungarianKey,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<GraphProvider>(
                    create: createProvider(AssignmentRules()),
                    child: AssignmentScreen(mainProvider: graphProvider),
                  ),
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
          const SizedBox(height: 17),
          FloatingActionButton(
            key: _matrixKey,
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
              key: _menuKey,
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