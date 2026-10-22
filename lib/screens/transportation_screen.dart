import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/transportation.dart';
import '../models/matrix_data.dart';
import '../providers/graph_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import '../widgets/overlays/highlight_overlay.dart';
import 'transportation_steps_screen.dart';

/// Problema de transporte sobre el grafo.
///
/// Los nodos con aristas salientes son los orígenes (filas), los nodos con
/// aristas entrantes son los destinos (columnas) y el peso de cada arista es el
/// costo de enviar una unidad por esa ruta. Se pide la oferta de cada origen y
/// la demanda de cada destino, se obtiene la solución inicial por esquina
/// noroeste y se mejora con MODI hasta el óptimo.
///
/// Igual que AssignmentScreen y JohnsonScreen, trabaja sobre una COPIA del grafo
/// (el provider que recibe de _pushWithCopy en home.dart).
class TransportationScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const TransportationScreen({super.key, required this.mainProvider});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  late final GraphProvider _copy;
  late String _lastAppliedJson;

  TransportationResult? _result;
  List<String> _sourceNames = const [];
  List<String> _destinationNames = const [];
  Set<String> _flowEdgeIds = {};

  // Último texto escrito para cada nodo (por id), para no volver a escribirlo.
  final Map<String, String> _supplyText = {};
  final Map<String, String> _demandText = {};

  @override
  void initState() {
    super.initState();
    _copy = context.read<GraphProvider>();
    _copy.addListener(_clearResult);
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());
  }

  @override
  void dispose() {
    _copy.removeListener(_clearResult);
    super.dispose();
  }

  // Si el grafo cambia, el resultado ya no corresponde a lo que se ve.
  void _clearResult() {
    if (_result == null) return;
    setState(() {
      _result = null;
      _flowEdgeIds = {};
    });
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Future<void> _solve(TransportGoal goal) async {
    final MatrixData matrix = _copy.buildMatrixData();
    final rows = matrix.rowHeaders;
    final cols = matrix.colHeaders;

    final inputs = await showDialog<_TransportInputs>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SupplyDemandDialog(
        goal: goal,
        sourceNames: [for (final n in rows) n.name],
        destinationNames: [for (final n in cols) n.name],
        initialSupply: [for (final n in rows) _supplyText[n.id] ?? ''],
        initialDemand: [for (final n in cols) _demandText[n.id] ?? ''],
      ),
    );
    if (inputs == null || !mounted) return;

    for (var i = 0; i < rows.length; i++) {
      _supplyText[rows[i].id] = inputs.supplyText[i];
    }
    for (var j = 0; j < cols.length; j++) {
      _demandText[cols[j].id] = inputs.demandText[j];
    }

    // null = no hay arista entre ese origen y ese destino (ruta inexistente).
    final costs = [
      for (var i = 0; i < rows.length; i++)
        [
          for (var j = 0; j < cols.length; j++)
            matrix.hasEdge[i][j] ? matrix.matrix[i][j] : null,
        ],
    ];

    final TransportationResult result;
    try {
      result = TransportationAlgorithm.solve(TransportationProblem(
        costs: costs,
        supply: inputs.supply,
        demand: inputs.demand,
        goal: goal,
      ));
    } catch (e, st) {
      debugPrint('Transportation error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return;
    }

    final flowEdgeIds = <String>{};
    if (!result.isInfeasible) {
      for (final flow in result.realFlows) {
        final id = matrix.edgeIds[flow.row][flow.col];
        if (id.isNotEmpty) flowEdgeIds.add(id);
      }
    }

    setState(() {
      _result = result;
      _sourceNames = [for (final n in rows) n.name];
      _destinationNames = [for (final n in cols) n.name];
      _flowEdgeIds = flowEdgeIds;
    });
    _showSummary(result);
  }

  void _openSteps() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransportationStepsScreen(
          result: result,
          sourceNames: _sourceNames,
          destinationNames: _destinationNames,
        ),
      ),
    );
  }

  void _showSummary(TransportationResult result) {
    final flows = result.realFlows;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result.isInfeasible)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No solution: the existing edges can't cover all the supply and demand.",
                      ),
                    )
                  else ...[
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: flows.length,
                        itemBuilder: (BuildContext context, int i) {
                          final flow = flows[i];
                          final unitCost = result.costs[flow.row][flow.col]!;
                          return ListTile(
                            title: Text(
                              "${_sourceNames[flow.row]} -> ${_destinationNames[flow.col]}",
                            ),
                            subtitle: Text("${_fmt(flow.amount)} units x ${_fmt(unitCost)}"),
                            trailing: Text(_fmt(flow.amount * unitCost)),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Total:'),
                      subtitle: Text(
                        'Northwest corner: ${_fmt(result.initialCost)}'
                        ' · MODI steps: ${result.iterations.length}',
                      ),
                      trailing: Text(_fmt(result.totalCost)),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openSteps();
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Show steps'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final List<String> messages = _copy.validateGraph();
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final bool canSolve = _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;

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
        default:
          break;
      }
    }

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: ((didPop, _) {
        if (didPop) return;
        showConfirmExitDialog(context, _copy);
      }),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Transportation"),
          actions: [
            IconButton(
              icon: const Icon(Icons.publish),
              tooltip: "Apply to main graph",
              onPressed: hasChanges
                  ? () {
                      widget.mainProvider.replaceGraph(_copy.snapshot());
                      setState(() {
                        _lastAppliedJson = currentGraph;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Graph Updated')),
                      );
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: "Undo",
              onPressed: graphProviderCopy.canUndo ? () => graphProviderCopy.undo() : null,
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: "Show steps",
              onPressed: _result != null ? _openSteps : null,
            ),
            PopupMenuButton<MenuOption>(
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
              ],
            ),
          ],
        ),
        body: GraphWidget(
          canvasOverlay: HighlightOverlay(_flowEdgeIds, AppColors.assignmentEdge),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (messages.isNotEmpty)
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
                        onPressed: canSolve ? () => _solve(TransportGoal.minimize) : null,
                        icon: const Icon(Icons.trending_down),
                        label: const Text('Minimize'),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSolve ? () => _solve(TransportGoal.maximize) : null,
                        icon: const Icon(Icons.trending_up),
                        label: const Text('Maximize'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que devuelve el diálogo de oferta y demanda.
class _TransportInputs {
  final List<String> supplyText;
  final List<String> demandText;
  final List<double> supply;
  final List<double> demand;
  const _TransportInputs(
      this.supplyText, this.demandText, this.supply, this.demand);
}

/// Pide la oferta de cada origen y la demanda de cada destino.
class _SupplyDemandDialog extends StatefulWidget {
  final TransportGoal goal;
  final List<String> sourceNames;
  final List<String> destinationNames;
  final List<String> initialSupply;
  final List<String> initialDemand;

  const _SupplyDemandDialog({
    required this.goal,
    required this.sourceNames,
    required this.destinationNames,
    required this.initialSupply,
    required this.initialDemand,
  });

  @override
  State<_SupplyDemandDialog> createState() => _SupplyDemandDialogState();
}

class _SupplyDemandDialogState extends State<_SupplyDemandDialog> {
  late final List<TextEditingController> _supplyCtrls;
  late final List<TextEditingController> _demandCtrls;
  String? _error;

  @override
  void initState() {
    super.initState();
    _supplyCtrls = [
      for (final t in widget.initialSupply) TextEditingController(text: t),
    ];
    _demandCtrls = [
      for (final t in widget.initialDemand) TextEditingController(text: t),
    ];
  }

  @override
  void dispose() {
    for (final c in _supplyCtrls) {
      c.dispose();
    }
    for (final c in _demandCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  void _submit() {
    final supply = [for (final c in _supplyCtrls) _parse(c.text)];
    final demand = [for (final c in _demandCtrls) _parse(c.text)];
    final valid = [...supply, ...demand].every((v) => v != null && v.isFinite && v >= 0);
    if (!valid) {
      setState(() => _error = 'Enter a number (0 or more) in every field.');
      return;
    }
    Navigator.of(context).pop(_TransportInputs(
      [for (final c in _supplyCtrls) c.text],
      [for (final c in _demandCtrls) c.text],
      [for (final v in supply) v!],
      [for (final v in demand) v!],
    ));
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalText =
        widget.goal == TransportGoal.minimize ? 'Minimize cost' : 'Maximize cost';
    final error = _error;

    return AlertDialog(
      title: Text(goalText),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supply of each source',
                  style: Theme.of(context).textTheme.titleSmall),
              for (var i = 0; i < _supplyCtrls.length; i++)
                _field(_supplyCtrls[i], widget.sourceNames[i]),
              const SizedBox(height: 16),
              Text('Demand of each destination',
                  style: Theme.of(context).textTheme.titleSmall),
              for (var j = 0; j < _demandCtrls.length; j++)
                _field(_demandCtrls[j], widget.destinationNames[j]),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Solve'),
        ),
      ],
    );
  }
}
