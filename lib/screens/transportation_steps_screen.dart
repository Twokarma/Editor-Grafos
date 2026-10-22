import 'package:flutter/material.dart';

import '../algorithms/transportation.dart';
import '../theme/app_colors.dart';

/// Paso a paso de la solución del problema de transporte:
/// esquina noroeste, cada iteración de MODI y la solución final.
class TransportationStepsScreen extends StatelessWidget {
  final TransportationResult result;

  /// Nombres de los orígenes (filas) y destinos (columnas) reales. La fila o
  /// columna ficticia, si existe, se agrega aquí como "Dummy".
  final List<String> sourceNames;
  final List<String> destinationNames;

  const TransportationStepsScreen({
    super.key,
    required this.result,
    required this.sourceNames,
    required this.destinationNames,
  });

  List<String> get _rowNames => [
        ...sourceNames,
        if (result.hasDummyRow) 'Dummy',
      ];

  List<String> get _colNames => [
        ...destinationNames,
        if (result.hasDummyCol) 'Dummy',
      ];

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _cellName(TransportCell c) => '${_rowNames[c.row]} -> ${_colNames[c.col]}';

  Widget _cell(BuildContext context, String text,
      {String? small, bool header = false, Color? background}) {
    return Container(
      width: 72,
      height: 52,
      alignment: Alignment.center,
      color: background,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (small != null)
            Text(small,
                style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: header ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(List<TableRow> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: AppColors.matrixBorders),
        defaultColumnWidth: const FixedColumnWidth(72),
        children: rows,
      ),
    );
  }

  /// Tabla de transporte: costo unitario (pequeño) y cantidad enviada (grande).
  /// La cantidad solo se muestra en las celdas básicas.
  Widget _allocationTable(
    BuildContext context,
    List<List<double>> alloc,
    List<List<bool>> basic, {
    Map<TransportCell, Color> marks = const {},
  }) {
    final rowNames = _rowNames;
    final colNames = _colNames;
    final headerBg = AppColors.headerBk;
    final summaryBg = AppColors.summaryBk;

    return _table([
      TableRow(children: [
        _cell(context, '', background: headerBg),
        for (final name in colNames)
          _cell(context, name, header: true, background: headerBg),
        _cell(context, 'Supply', header: true, background: headerBg),
      ]),
      for (var i = 0; i < rowNames.length; i++)
        TableRow(children: [
          _cell(context, rowNames[i], header: true, background: headerBg),
          for (var j = 0; j < colNames.length; j++)
            _cell(
              context,
              basic[i][j] ? _fmt(alloc[i][j]) : '',
              small: result.costs[i][j] == null ? '-' : _fmt(result.costs[i][j]!),
              background: marks[TransportCell(i, j)],
            ),
          _cell(context, _fmt(result.supply[i]), background: summaryBg),
        ]),
      TableRow(children: [
        _cell(context, 'Demand', header: true, background: headerBg),
        for (var j = 0; j < colNames.length; j++)
          _cell(context, _fmt(result.demand[j]), background: summaryBg),
        _cell(context, '', background: headerBg),
      ]),
    ]);
  }

  Widget _deltaTable(BuildContext context, TransportationIteration it) {
    final rowNames = _rowNames;
    final colNames = _colNames;
    final headerBg = AppColors.headerBk;
    final summaryBg = AppColors.summaryBk;
    final highlight = Theme.of(context).colorScheme.primaryContainer;

    return _table([
      TableRow(children: [
        _cell(context, '', background: headerBg),
        for (final name in colNames)
          _cell(context, name, header: true, background: headerBg),
        _cell(context, 'u', header: true, background: headerBg),
      ]),
      for (var i = 0; i < rowNames.length; i++)
        TableRow(children: [
          _cell(context, rowNames[i], header: true, background: headerBg),
          for (var j = 0; j < colNames.length; j++)
            _cell(
              context,
              it.deltas[i][j] == null ? '-' : _fmt(it.deltas[i][j]!),
              background: it.entering == TransportCell(i, j) ? highlight : null,
            ),
          _cell(context, _fmt(it.u[i]), background: summaryBg),
        ]),
      TableRow(children: [
        _cell(context, 'v', header: true, background: headerBg),
        for (var j = 0; j < colNames.length; j++)
          _cell(context, _fmt(it.v[j]), background: summaryBg),
        _cell(context, '', background: headerBg),
      ]),
    ]);
  }

  Widget _title(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _summary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = result;

    if (r.isInfeasible) {
      return Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "No solution: the existing edges can't cover all the supply and demand.",
            style: TextStyle(color: scheme.onErrorContainer),
          ),
        ),
      );
    }

    final kind = r.goal == TransportGoal.minimize ? 'minimum' : 'maximum';
    final notes = <String>[
      if (r.hasDummyCol)
        'Supply is larger than demand, so a dummy destination was added. '
            'What is assigned to it is not shipped.',
      if (r.hasDummyRow)
        'Demand is larger than supply, so a dummy source was added. '
            'What is assigned to it is not covered.',
      if (r.goal == TransportGoal.maximize)
        'When maximizing, the method minimizes the negated costs, so u, v and '
            'the reduced costs are shown with that sign.',
      if (r.hitIterationLimit)
        'The iteration limit was reached; the result may not be optimal.',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total cost ($kind): ${_fmt(r.totalCost)}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(r.iterations.isEmpty
                ? 'The northwest corner solution was already optimal.'
                : 'Improved in ${r.iterations.length} '
                    'step${r.iterations.length == 1 ? '' : 's'} '
                    '(from ${_fmt(r.initialCost)} to ${_fmt(r.totalCost)}).'),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(note, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iterationTile(BuildContext context, int k) {
    final it = result.iterations[k];
    final scheme = Theme.of(context).colorScheme;
    final marks = <TransportCell, Color>{
      it.entering: scheme.primaryContainer,
      it.leaving: scheme.errorContainer,
    };

    String names(List<TransportCell> cells) => cells.map(_cellName).join(', ');

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Step ${k + 1}'),
      subtitle: Text('In: ${_cellName(it.entering)}, out: ${_cellName(it.leaving)}'
          ' · cost ${_fmt(it.costAfter)}'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reduced costs = c - u - v (highlighted: the most negative one, '
          'the route that enters):',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        _deltaTable(context, it),
        const SizedBox(height: 12),
        Text(
          'Cycle: add (+) ${names(it.plusCells)}; subtract (-) ${names(it.minusCells)}.\n'
          'Units moved around the cycle: ${_fmt(it.theta)}.',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text('Result (highlighted: enters, red: leaves):',
            style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        _allocationTable(context, it.allocationAfter, it.basicAfter, marks: marks),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = result;

    return Scaffold(
      appBar: AppBar(title: const Text('Transportation steps')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summary(context),
          _title(context, '1. Northwest corner (initial solution)'),
          const Text(
            'Start at the top-left cell and assign as much as possible, moving '
            'right or down. In each cell the small number is the unit cost and '
            'the big one is the quantity shipped.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          _allocationTable(context, r.initialAllocation, r.initialBasic),
          const SizedBox(height: 8),
          Text('Initial cost: ${_fmt(r.initialCost)}'
              '${r.initialUsesMissingRoutes ? ' (it uses routes that do not exist; this is fixed while optimizing)' : ''}'),
          _title(context, '2. Optimization (MODI method)'),
          if (r.iterations.isEmpty)
            const Text('The initial solution is already optimal: every reduced cost is 0 or more.')
          else ...[
            const Text(
              'Compute the potentials u and v and the reduced cost of every empty '
              'cell. If any is negative, that route lowers the cost: it enters the '
              'basis and the quantities are adjusted around a cycle. Repeat until '
              'no reduced cost is negative.',
              style: TextStyle(fontSize: 13),
            ),
            for (var k = 0; k < r.iterations.length; k++) _iterationTile(context, k),
          ],
          if (!r.isInfeasible) ...[
            _title(context, '3. Final solution'),
            _allocationTable(context, r.allocation, r.basic),
            const SizedBox(height: 12),
            for (final flow in r.realFlows)
              Text('${sourceNames[flow.row]} -> ${destinationNames[flow.col]}: '
                  '${_fmt(flow.amount)} units x ${_fmt(r.costs[flow.row][flow.col]!)}'),
          ],
        ],
      ),
    );
  }
}
