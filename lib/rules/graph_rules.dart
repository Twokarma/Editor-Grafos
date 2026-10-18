import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/models/graph.dart';

import '../models/node.dart';

abstract class GraphRules {

  bool forcesDirected() => false;

  String? checkAddNode(Graph graph, double x, double y){
    String nodeId = "";
    double radius = graph.radius;
    for(Node node in graph.nodes.values){
      double dx = node.x - x;
      double dy = node.y - y;
      double d = (dx * dx) + (dy * dy);
      if( d <= (radius+radius+3) * (radius+radius+3)) {
          nodeId = "tooClose";
      }
    }
    return  nodeId == ""? null : "Can't create a node that close to another";
  }

  String? checkMoveNode(Graph graph, String nodeId, double x, double y){
    double radius = graph.radius;
    final node = graph.nodes[nodeId];
    if (node == null) return "There's no node";

    for (final entry in graph.nodes.entries) {
      if (entry.key == nodeId) continue;
      final dx = entry.value.x - x;
      final dy = entry.value.y - y;
      if ((dx * dx + dy * dy) <= (radius + radius + 3) * (radius + radius + 3)) {
        return "Can't move a node that close to another";
      }
    }

    return null;
  }

  String? checkEdgeEndpoints(Graph graph, String fromId, String toId){
    Edge? reversed = graph.findReverseEdge(fromId, toId);
    if(reversed != null && !reversed.directed) return "The edge already exists";
    return graph.edgeExists(fromId, toId)? "The edge already exists" : null;
  }

  String? checkAddEdge(Graph graph, String fromId, String toId, bool directed){
    String? message = checkEdgeEndpoints(graph, fromId, toId);
    return message;
  }

  String? checkRemoveNode(Graph graph, String nodeId){
    return null;
  }

  String? checkRemoveEdge(Graph graph, String edgeId){
    return null;
  }

  List<String> validateGraph(Graph graph){
    return [];
  }
}

class DefaultRules extends GraphRules{}