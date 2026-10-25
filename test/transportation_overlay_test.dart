import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/transportation.dart';
import 'package:graph_maker_app_2/models/matrix_data.dart';
import 'package:graph_maker_app_2/models/node.dart';
import 'package:graph_maker_app_2/services/transportation_overlay_builder.dart';

/// Matriz con 2 orígenes (A, B) a la izquierda y 3 destinos (X, Y, Z) a la derecha.
/// Todas las rutas existen; la arista (i, j) tiene id "e{i}{j}".
MatrixData buildMatrix(List<List<double>> costs) {
  final sources = [Node('a', 'A', 0, 0, 30), Node('b', 'B', 0, 200, 30)];
  final dests = [
    Node('x', 'X', 400, 0, 30),
    Node('y', 'Y', 400, 100, 30),
    Node('z', 'Z', 400, 200, 30),
  ];
  return MatrixData(
    nodes: [...sources, ...dests],
    rowHeaders: sources,
    colHeaders: dests,
    matrix: costs,
    hasEdge: [
      for (final r in costs) [for (final _ in r) true]
    ],
    edgeIds: [
      for (var i = 0; i < costs.length; i++)
        [for (var j = 0; j < costs[i].length; j++) 'e$i$j']
    ],
    rowSum: List.filled(costs.length, 0),
    colSum: List.filled(costs[0].length, 0),
    rowDegree: List.filled(costs.length, costs[0].length),
    colDegree: List.filled(costs[0].length, costs.length),
  );
}

TransportationResult solve(MatrixData m, List<double> supply, List<double> demand) {
  return TransportationAlgorithm.solve(TransportationProblem(
    costs: [
      for (var i = 0; i < m.matrix.length; i++) [for (final c in m.matrix[i]) c]
    ],
    supply: supply,
    demand: demand,
  ));
}

void main() {
  final costs = [
    [4.0, 6.0, 8.0],
    [5.0, 3.0, 7.0],
  ];

  test('balanceado: no hay nodo fantasma', () {
    final m = buildMatrix(costs);
    final r = solve(m, [30.0, 30.0], [20.0, 25.0, 15.0]);
    final o = TransportationOverlayBuilder.build(m, r);
    expect(o.nodes, isEmpty);
    expect(o.edges, isEmpty);
    expect(o.highlightedEdgeIds, isNotEmpty);
  });

  test('oferta mayor que la demanda: un destino fantasma recibe desde cada origen', () {
    final m = buildMatrix(costs);
    final r = solve(m, [40.0, 30.0], [20.0, 25.0, 15.0]);
    expect(r.hasDummyCol, isTrue);
    final o = TransportationOverlayBuilder.build(m, r);

    expect(o.nodes, hasLength(1));
    final ghost = o.nodes.first;
    expect(ghost.x, 400); // misma columna que el destino más bajo (Z)
    expect(ghost.y, greaterThan(200)); // debajo de él

    expect(o.edges, hasLength(2)); // una por origen
    for (final e in o.edges) {
      expect(e.targetId, ghost.id);
    }
    // Lo que se manda al fantasma es el exceso de oferta (70 - 60 = 10).
    final sentToGhost = o.edges.where((e) => e.assigned).length;
    expect(sentToGhost, greaterThan(0));
    expect(o.edges.where((e) => e.assigned).every((e) => e.label!.endsWith('units')), isTrue);
  });

  test('demanda mayor que la oferta: un origen fantasma envía a cada destino', () {
    final m = buildMatrix(costs);
    final r = solve(m, [20.0, 30.0], [20.0, 25.0, 15.0]);
    expect(r.hasDummyRow, isTrue);
    final o = TransportationOverlayBuilder.build(m, r);

    expect(o.nodes, hasLength(1));
    final ghost = o.nodes.first;
    expect(ghost.x, 0); // misma columna que el origen más bajo (B)
    expect(ghost.y, greaterThan(200));

    expect(o.edges, hasLength(3)); // una por destino
    for (final e in o.edges) {
      expect(e.sourceId, ghost.id);
    }
  });

  test('sin solución: no dibuja nada', () {
    final m = buildMatrix(costs);
    final r = TransportationAlgorithm.solve(TransportationProblem(
      costs: const [
        [4.0, null, null],
        [5.0, null, null],
      ],
      supply: const [10.0, 10.0],
      demand: const [10.0, 5.0, 5.0],
    ));
    expect(r.isInfeasible, isTrue);
    final o = TransportationOverlayBuilder.build(m, r);
    expect(o.nodes, isEmpty);
    expect(o.highlightedEdgeIds, isEmpty);
  });
}
