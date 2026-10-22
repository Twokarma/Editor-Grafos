import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/screens/johnson_matrix_screen.dart';
import 'package:graph_maker_app_2/services/johnson_service.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:graph_maker_app_2/widgets/overlays/johnson_overlay.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/node.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import 'chat_screen.dart';

// ★ AYUDA: imports nuevos
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../widgets/graph_tour.dart';

import 'pdf_viewer_screen.dart'; // ★ MANUAL: openManual()

class JohnsonScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const JohnsonScreen({super.key, required this.mainProvider});

  @override
  State<JohnsonScreen> createState() => _JohnsonScreenState();
}

class _JohnsonScreenState extends State<JohnsonScreen> {
  JohnsonResult1? _lastResult;
  String _lastSignature = ''; // ★ ya no es late: evita errores si el listener se dispara antes
  late String _lastAppliedJson;
  JohnsonService? _service;
  Objective _objective = Objective.max;
  String? _from;
  String? _to;
  Set<String> _pathEdgeIds = {};
  String? _message;
  bool _hasChanges = true;

  late final GraphProvider _copy;

  // ★ AYUDA: keys de cada botón que explica el tour
  final _publishKey = GlobalKey();
  final _undoKey = GlobalKey();
  final _menuKey = GlobalKey();
  final _helpKey = GlobalKey();
  final _matrixKey = GlobalKey();
  final _fromKey = GlobalKey();
  final _toKey = GlobalKey();
  final _objectiveKey = GlobalKey();

  // ★ AYUDA: pasos del tour
  void _startTour() {
    GraphTour.show(context, [
      TourStep(_publishKey, 'Aplicar al grafo principal',
          'Envía los cambios de esta copia al grafo principal. Se activa solo cuando hay cambios.'),
      TourStep(_undoKey, 'Deshacer',
          'Revierte la última acción en esta copia del grafo.'),
      TourStep(_menuKey, 'Más opciones',
          'Guardar, abrir, limpiar el grafo o abrir el chat con el asistente.'),
      TourStep(_matrixKey, 'Matriz M[x]',
          'Muestra las matrices de distancias calculadas por Johnson.',
          align: ContentAlign.left),
      TourStep(_fromKey, 'Origen (From)',
          'Vértice desde el que se calcula el camino.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_toKey, 'Destino (To)', 'Vértice al que quieres llegar.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_objectiveKey, 'Maximizar / Minimizar',
          'Cambia entre el camino de mayor costo y el de menor costo.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
    ]);
  }

  @override
  void initState() {
    super.initState();

    _copy = context.read<GraphProvider>();
    _copy.addListener(_onGraphChanged);
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());

    // ★ setState dentro de _runJohnson: se ejecuta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runJohnson();
    });
  }

  void _onGraphChanged() {
    // Sin setState ni postFrameCallback: context.watch ya reconstruye la
    // pantalla, y el camino viejo debe limpiarse antes de ese build
    // (si no, _buildTextPath busca aristas borradas).
    if (_lastSignature != _structureSignature()) {
      _lastResult = null;
      _pathEdgeIds = {};
      _message = null;
      _hasChanges = true;
    } else {
      _hasChanges = false;
    }
  }

  @override
  void dispose() {
    _copy.removeListener(_onGraphChanged);
    super.dispose();
  }

  void _fail(String message) {
    setState(() {
      _service = null;
      _lastResult = null;
      _pathEdgeIds = <String>{};
      _from = null;
      _to = null;
      _message = message;
    });
  }

  void _runJohnson() {
    _lastSignature = _structureSignature();
    List<Node> nodes = _copy.graphGetter().nodes.values.toList();
    List<Edge> edges = _copy.graphGetter().edges.values.toList();

    if (edges.isEmpty) {
      _fail("There are no edges");
      return;
    }

    List<String> messages = _copy.validateGraph();
    if (messages.isNotEmpty) {
      // ★ CORRECCIÓN: faltaba el return
      _fail(messages.first);
      return;
    }

    Set<String> sources = {};
    Set<String> targets = {};
    for (Edge edge in edges) {
      sources.add(edge.sourceNodeId);
      targets.add(edge.targetNodeId);
    }

    // ★ CORRECCIÓN: ambas diferencias se calculan sobre los conjuntos originales
    final Set<String> nodesFrom = sources.difference(targets);
    final Set<String> nodesTo = targets.difference(sources);

    if (nodesFrom.isEmpty || nodesTo.isEmpty) {
      _fail("No start or end node");
      return;
    }
    final String nodeFrom = nodesFrom.first;
    final String nodeTo = nodesTo.first;

    _service = JohnsonService(
        nodes: nodes, edges: edges, nodeFrom: nodeFrom, nodeTo: nodeTo);
    JohnsonResult1 result = _service!.run();

    int n = result.distanceMax.length;
    for (int i = 0; i < n; i++) {
      if (result.distanceMax[i][i] != 0 || result.distanceMin[i][i] != 0) {
        _fail("Cycle detected");
        return;
      }
    }
    setState(() {
      _lastResult = result;
      _from = _service?.nodeFrom;
      _to = _service?.nodeTo;
      _hasChanges = false;
      _message = null;
    });

    _pathUpdate();
  }

  String _structureSignature() {
    return _copy
        .graphGetter()
        .edges
        .values
        .map((e) => [
              e.id,
              e.sourceNodeId,
              e.targetNodeId,
              e.weight,
              e.directed,
            ])
        .toList()
        .toString();
  }

  void _pathUpdate() {
    if (_service == null ||
        _lastResult == null ||
        _from == null ||
        _to == null) {
      setState(() {
        _pathEdgeIds = <String>{};
      });
      return;
    }
    final Set<String> path = _service!.path(_objective, from: _from, to: _to);

    // ★ un solo setState
    setState(() {
      if (path.isEmpty || _from == _to) {
        _message =
            "No path from ${_service!.nodes[_service!.index[_from]!].name} to ${_service!.nodes[_service!.index[_to]!].name}";
      } else {
        _message = null;
      }
      _pathEdgeIds = path;
    });
  }

  String _buildTextPath() {
    if (_pathEdgeIds.isEmpty) return '';

    final List<String> copy = _pathEdgeIds.toList();
    final Map<String, Node> nodes = _copy.graphGetter().nodes;
    final Map<String, Edge> edges = _copy.graphGetter().edges;

    String path = "";
    for (int i = copy.length - 2; i >= 0; i--) {
      path += "${nodes[edges[copy[i]]!.sourceNodeId]!.name} -> ";
    }
    // ★ aviso corregido: interpolación innecesaria
    path += nodes[edges[copy[0]]!.targetNodeId]!.name;

    // JohnsonService.path() agrega la distancia total como último elemento
    return "$path = ${copy[copy.length - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final List<String> messages = _copy.validateGraph();
    final bool canSolve =
        _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;

    void handleMenuSelection(BuildContext context, MenuOption option) {
      switch (option) {
        case MenuOption.save:
          showSaveDialog(context, graphProviderCopy);
          break;
        case MenuOption.open:
          showOpenDialog(context, graphProviderCopy);
          break;
        case MenuOption.clear:
          graphProviderCopy.clearGraph();
          break;
        case MenuOption.chat:
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                      value: _copy,
                      child: const ChatScreen(),
                    )),
          );
          break;
        // ★ MANUAL: abre graph_maker_guia_rapida.pdf
        case MenuOption.manual:
          openManual(context);
          break;
      }
    }

    final List<DropdownMenuEntry<String>> dropdownMenuEntries = [
      if (_service != null)
        for (final Node node in _service!.nodes)
          DropdownMenuEntry<String>(value: node.id, label: node.name),
    ];

    return PopScope(
        canPop: !hasChanges,
        onPopInvokedWithResult: ((didPop, result) {
          if (didPop) return;
          showConfirmExitDialog(context, _copy);
        }),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Johnson"),
            actions: [
              IconButton(
                key: _publishKey, // ★ AYUDA
                icon: const Icon(Icons.publish),
                tooltip: "Apply to main graph",
                onPressed: hasChanges
                    ? () {
                        widget.mainProvider.replaceGraph(_copy.snapshot());
                        setState(() {
                          _lastAppliedJson = currentGraph;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Graph Updated')));
                      }
                    : null,
              ),
              IconButton(
                key: _undoKey, // ★ AYUDA
                icon: const Icon(Icons.undo),
                tooltip: "Undo",
                onPressed: graphProviderCopy.canUndo
                    ? () => graphProviderCopy.undo()
                    : null,
              ),

              // ★ AYUDA: botón que lanza el tour
              IconButton(
                key: _helpKey,
                icon: const Icon(Icons.help_outline),
                tooltip: "Help",
                onPressed: _startTour,
              ),

              PopupMenuButton<MenuOption>(
                key: _menuKey, // ★ AYUDA
                onSelected: (option) => handleMenuSelection(context, option),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<MenuOption>>[
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.save,
                    child: ListTile(
                      leading: Icon(Icons.save_outlined),
                      title: Text('Save'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.open,
                    child: ListTile(
                      leading: Icon(Icons.folder_open_outlined),
                      title: Text('Open'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.clear,
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Clear'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.chat,
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline),
                      title: Text('ChatAI'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.manual,
                    child: ListTile(
                      leading: Icon(Icons.menu_book_outlined),
                      title: Text('Manual'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: GraphWidget(
              canvasOverlay: JohnsonOverlay(
                  _pathEdgeIds,
                  _objective == Objective.max? AppColors.maxJohnson : AppColors.minJohnson,
                  _lastResult != null? _lastResult!.holgura : <String, double>{}
              ),
          ),
          floatingActionButton: FloatingActionButton(
            key: _matrixKey, // ★ AYUDA
            onPressed: _lastResult != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                                value: _copy,
                                child: JohnsonMatrixScreen(
                                    nodes: _service!.nodes,
                                    result: _service!.result),
                              )),
                    );
                  }
                : null,
            shape: const CircleBorder(),
            child: const Text(
              "M[x]",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
          bottomNavigationBar: SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ★ Único lugar donde se muestra el camino o el mensaje
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _pathEdgeIds.isNotEmpty
                        ? _buildTextPath()
                        : (_message ?? ''),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: _lastResult == null
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      // ★ GlobalKey en el Container (tour), ValueKey en el dropdown (refresco)
                      child: Container(
                        key: _fromKey,
                        child: DropdownMenu<String>(
                          key: ValueKey('from_$_from'),
                          expandedInsets: EdgeInsets.zero,
                          initialSelection: _from,
                          label: const Text('From'),
                          requestFocusOnTap: false,
                          enabled: _lastResult != null,
                          menuHeight: 300,
                          dropdownMenuEntries: dropdownMenuEntries,
                          onSelected: (String? selection) {
                            setState(() {
                              _from = selection;
                            });
                            _pathUpdate();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Container(
                        key: _toKey,
                        child: DropdownMenu<String>(
                          key: ValueKey('to_$_to'),
                          expandedInsets: EdgeInsets.zero,
                          initialSelection: _to,
                          label: const Text('To'),
                          requestFocusOnTap: false,
                          enabled: _lastResult != null,
                          menuHeight: 300,
                          dropdownMenuEntries: dropdownMenuEntries,
                          onSelected: (String? selection) {
                            setState(() {
                              _to = selection;
                            });
                            _pathUpdate();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Row(
                  key: _objectiveKey, // ★ AYUDA
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSolve
                            ? () {
                                setState(() {
                                  _objective = Objective.min;
                                });
                                if (_hasChanges) _runJohnson();
                                _pathUpdate();
                              }
                            : null,
                        icon: const Icon(Icons.trending_down),
                        label: const Text('Minimize'),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSolve
                            ? () {
                                setState(() {
                                  _objective = Objective.max;
                                });
                                if (_hasChanges) _runJohnson();
                                _pathUpdate();
                              }
                            : null,
                        icon: const Icon(Icons.trending_up),
                        label: const Text('Maximize'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ));
  }
}