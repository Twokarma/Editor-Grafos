import 'package:graph_maker_app_2/algorithms/transportation.dart';
import 'package:graph_maker_app_2/models/assignment_overlay.dart';
import 'package:graph_maker_app_2/models/matrix_data.dart';
import 'package:graph_maker_app_2/services/assignment_service.dart';

/// Arma lo que se dibuja sobre el grafo después de resolver el transporte:
/// las rutas con envío resaltadas y, si hubo que balancear, el nodo fantasma.
///
/// - Oferta mayor que la demanda: se agrega un destino fantasma. Lo que se le
///   "envía" en realidad se queda en el origen.
/// - Demanda mayor que la oferta: se agrega un origen fantasma. Lo que "envía"
///   es demanda que no se alcanza a cubrir.
///
/// Reutiliza GhostNode/GhostEdge y AssignmentCanvasOverlay, los mismos que usa
/// la pantalla de asignación.
class TransportationOverlayBuilder {
  static AssignmentOverlay build(MatrixData matrix, TransportationResult result) {
    if (result.isInfeasible) return AssignmentOverlay();

    final rows = matrix.rowHeaders; // orígenes
    final cols = matrix.colHeaders; // destinos

    final highlighted = <String>{};
    for (final flow in result.realFlows) {
      final id = matrix.edgeIds[flow.row][flow.col];
      if (id.isNotEmpty) highlighted.add(id);
    }

    final bool dummyRow = result.hasDummyRow;
    final bool dummyCol = result.hasDummyCol;
    if (!dummyRow && !dummyCol) {
      return AssignmentOverlay(highlightedEdgeIds: highlighted);
    }

    // El fantasma se coloca debajo del nodo más bajo del lado al que pertenece:
    // un origen fantasma junto a los orígenes, un destino fantasma junto a los destinos.
    final service = AssignmentService(matrix: matrix, mode: true);
    final ghosts = service.placeGhosts(dummyRow ? rows : cols, 1);
    if (ghosts.isEmpty) return AssignmentOverlay(highlightedEdgeIds: highlighted);
    final ghost = ghosts.first;

    final edges = <GhostEdge>[];
    if (dummyCol) {
      // Destino fantasma: columna extra de la matriz balanceada.
      for (var i = 0; i < result.realRows; i++) {
        final amount = result.allocation[i][result.realCols];
        edges.add(_edge(rows[i].id, ghost.id, amount));
      }
    } else {
      // Origen fantasma: fila extra de la matriz balanceada.
      for (var j = 0; j < result.realCols; j++) {
        final amount = result.allocation[result.realRows][j];
        edges.add(_edge(ghost.id, cols[j].id, amount));
      }
    }

    return AssignmentOverlay(nodes: ghosts, edges: edges, highlightedEdgeIds: highlighted);
  }

  /// Arista punteada hacia/desde el fantasma. Si lleva cantidad, se resalta y
  /// muestra cuántas unidades; si no, queda tenue con su costo 0.
  static GhostEdge _edge(String sourceId, String targetId, double amount) {
    final used = amount > 1e-9;
    return GhostEdge(
      sourceId,
      targetId,
      0,
      assigned: used,
      label: used ? '${_fmt(amount)} units' : null,
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
