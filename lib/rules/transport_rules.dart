import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

/// Reglas de edición para el problema de transporte.
///
/// Los nodos con aristas salientes son los orígenes y los nodos con aristas
/// entrantes son los destinos, así que un mismo nodo no puede ser ambos. Las
/// aristas son siempre dirigidas (origen -> destino) y no hay lazos.
class TransportRules extends GraphRules {
  @override
  bool forcesDirected() => true;

  @override
  String? checkEdgeEndpoints(Graph graph, String fromId, String toId) {
    final message = super.checkEdgeEndpoints(graph, fromId, toId);
    if (message != null) return message;

    if (fromId == toId) return "Self loops aren't allowed in Transportation";
    for (final edge in graph.edges.values) {
      if (edge.targetNodeId == fromId) {
        return "${graph.nodes[fromId]!.name} is already a destination";
      }
      if (edge.sourceNodeId == toId) {
        return "${graph.nodes[toId]!.name} is already a source";
      }
    }
    return null;
  }

  @override
  String? checkAddEdge(Graph graph, String fromId, String toId, bool directed) {
    final message = super.checkAddEdge(graph, fromId, toId, directed);
    if (message != null) return message;
    if (!directed) return "Non-directed edges aren't allowed in Transportation";
    return null;
  }

  @override
  List<String> validateGraph(Graph graph) {
    final edges = graph.edges.values.toList();
    for (final edge in edges) {
      if (!edge.directed) {
        return ["Non-directed edges aren't allowed in Transportation"];
      }
      if (edge.isLoop()) {
        return ["Self loops aren't allowed in Transportation"];
      }
    }

    final sources = {for (final e in edges) e.sourceNodeId};
    final destinations = {for (final e in edges) e.targetNodeId};
    for (final id in sources) {
      if (destinations.contains(id)) {
        return ["Node ${graph.nodes[id]!.name} can't have incoming and outgoing edges"];
      }
    }
    return [];
  }
}
