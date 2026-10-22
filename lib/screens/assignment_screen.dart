import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/hungarian_assignment.dart';
import 'package:graph_maker_app_2/models/assignment_overlay.dart';
import 'package:graph_maker_app_2/models/matrix_data.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/services/assignment_service.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/overlays/assignment_canvas_overlay.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../widgets/dialogs/confirm_exit_copy_dialog.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import 'chat_screen.dart';
import 'matrix_screen.dart';

// ★ AYUDA: imports nuevos
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../widgets/graph_tour.dart';

import 'pdf_viewer_screen.dart';
class AssignmentScreen extends StatefulWidget{
  final GraphProvider mainProvider;
  const AssignmentScreen({super.key, required this.mainProvider});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>{
  HungarianResult? _lastResult;
  AssignmentOverlay? _lastOverlay;
  late String _lastAppliedJson;

  late final GraphProvider _copy;

  // ★ AYUDA: keys de cada botón que explica el tour
  final _publishKey = GlobalKey();
  final _undoKey = GlobalKey();
  final _menuKey = GlobalKey();
  final _helpKey = GlobalKey();
  final _matrixKey = GlobalKey();
  final _minKey = GlobalKey();
  final _maxKey = GlobalKey();

  // ★ AYUDA: pasos del tour
  void _startTour() {
    GraphTour.show(context, [
      TourStep(_publishKey, 'Aplicar al grafo principal',
          'Envía los cambios de esta copia al grafo principal. Se activa solo cuando hay cambios.'),
      TourStep(_undoKey, 'Deshacer',
          'Revierte la última acción en esta copia del grafo.'),
      TourStep(_menuKey, 'Más opciones',
          'Guardar, abrir, limpiar el grafo o abrir el chat con el asistente.'),
      TourStep(_matrixKey, 'Matriz M[x]', 'Abre la matriz de costos del grafo.',
          align: ContentAlign.left),
      TourStep(_minKey, 'Minimize',
          'Calcula la asignación de menor costo total con el método húngaro.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_maxKey, 'Maximize',
          'Calcula la asignación de mayor costo total.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
    ]);
  }

  @override
  void initState(){
    super.initState();

    _copy = context.read<GraphProvider>();
    _copy.addListener(_listenerClear);
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());
  }

  void _listenerClear(){
    if(_lastResult == null) return;
    setState(()   {
      _lastResult = null;
      _lastOverlay = null;
    });
  }

  @override
  void dispose(){
    _copy.removeListener(_listenerClear);
    super.dispose();
  }

  void _runAssignment(bool min){
    MatrixData matrix = _copy.buildMatrixData();
    AssignmentService service = AssignmentService(matrix: matrix, mode: min);
    HungarianResult result = service.run();
    AssignmentOverlay overlay = service.buildOverlay(result);
    setState(() {
      _lastResult = result;
      _lastOverlay = overlay;
    });

    final List<AssignmentPair> assigned = overlay.pairs;
    String pairValue(AssignmentPair pair){
      switch(pair.kind){
        case AssignmentPairKind.real:
          return pair.weight.toString();
        case AssignmentPairKind.dummy:
          return "${pair.weight} (dummy)";
        case AssignmentPairKind.noEdge:
          return "(no edge)";
      }
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext ctx){
          return SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    // ★ CORRECCIÓN: se usa ctx (el contexto del bottom sheet) en lugar del de la pantalla
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(ctx).height * 0.6,
                        maxWidth: MediaQuery.sizeOf(ctx).width * 0.5),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ListView.builder(
                              itemCount: assigned.length,
                              itemBuilder: (BuildContext context, int i){
                                return ListTile(
                                  title: Text("${assigned[i].sourceName} -> ${assigned[i].targetName}"),
                                  trailing: Text(pairValue(assigned[i])),
                                );
                              },
                              shrinkWrap: true,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('Total:'),
                            trailing: Text(result.totalCost.toString()),
                          )
                        ],
                    ),
                  ),
              ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context){
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final List<String> messages = _copy.validateGraph();
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final bool canSolve = _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final overlay = _lastOverlay;

    void handleMenuSelection(BuildContext context, MenuOption option){
      switch(option){
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
            MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: _copy, child: const ChatScreen(),)),
          );
          break;
        // ★ CORRECCIÓN: faltaba este caso; el switch no era exhaustivo y la opción "Manual" no hacía nada
       case MenuOption.manual:
  openManual(
    context,
    title: 'Asignación',
    assetPath: 'assets/docs/guia_asignacion.pdf',
  );
  break;
      }
    }

    return PopScope(
        canPop: !hasChanges,
        // ★ CORRECCIÓN: el parámetro se renombra a "_" para no ocultar la variable "result" de arriba
        onPopInvokedWithResult: ((didPop, _) {
          if(didPop) return;
          showConfirmExitDialog(context, _copy);
        }),
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Assignment"),
              actions: [
                IconButton(
                  key: _publishKey, // ★ AYUDA
                  icon: const Icon(Icons.publish),
                  tooltip: "Apply to main graph",
                  onPressed: hasChanges ? () {
                    widget.mainProvider.replaceGraph(_copy.snapshot());
                    setState((){
                      _lastAppliedJson = currentGraph;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Graph Updated'),));
                  } : null,
                ),

                IconButton(
                  key: _undoKey, // ★ AYUDA
                  icon: const Icon(Icons.undo),
                  tooltip: "Undo",
                  onPressed: graphProviderCopy.canUndo ? () => graphProviderCopy.undo() : null,
                ),

                // ★ AYUDA: botón nuevo que lanza el tour
                IconButton(
                  key: _helpKey,
                  icon: const Icon(Icons.help_outline),
                  tooltip: "Help",
                  onPressed: _startTour,
                ),

                PopupMenuButton<MenuOption>(
                  key: _menuKey, // ★ AYUDA
                  onSelected: (option) => handleMenuSelection(context, option),

                  itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
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
                        leading: Icon(Icons.help_outline),
                        title: Text('Manual'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

              ],
            ),
          body: GraphWidget(
            canvasOverlay: AssignmentCanvasOverlay(
                overlay?.highlightedEdgeIds ?? const <String>{},
                AppColors.assignmentEdge,
                overlay?.nodes ?? const [],
                overlay?.edges ?? const []
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: _matrixKey, // ★ AYUDA
            onPressed: messages.isEmpty? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: _copy, child: const MatrixScreen(square: true),)),
              );
            } : null,
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
                      if(messages.isNotEmpty)
                        Text(
                          messages.first,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: _minKey, // ★ AYUDA
                              onPressed: canSolve? () {
                                _runAssignment(true);
                              } : null,
                              icon: const Icon(Icons.trending_down),
                              label: const Text('Minimize'),
                            ),
                          ),
                          const SizedBox(width: 8.0,),
                          Expanded(
                            child: FilledButton.icon(
                              key: _maxKey, // ★ AYUDA
                              onPressed: canSolve? () {
                                _runAssignment(false);
                              } : null,
                              icon: const Icon(Icons.trending_up),
                              label: const Text('Maximize'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
              )
          ),
        )
    );
  }
}