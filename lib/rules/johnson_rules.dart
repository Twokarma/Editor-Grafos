import 'dart:collection';

import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

import '../models/graph.dart';

class JohnsonRules extends GraphRules{
  @override
  bool forcesDirected() {
    return true;
  }

  @override
  String? checkEdgeEndpoints(Graph graph, String fromId, String toId) {
    String? message = super.checkEdgeEndpoints(graph, fromId, toId);
    if(message != null) return message;

    if(fromId == toId) return "Self loop aren't allowed in Johnson";
    if(graph.findReverseEdge(fromId, toId) != null) return "Reverse aren't allowed in Johnson";

    Set<String> visitedNodes = {};
    Queue<String> nodes = Queue();
    nodes.add(toId);
    List<Edge> edges = [];
    while(nodes.isNotEmpty){
      String nodeId = nodes.removeFirst();
      if(nodeId == fromId) return "This edge would create a cycle";
      if(visitedNodes.contains(nodeId)) continue;
      visitedNodes.add(nodeId);
      edges.addAll(graph.findEdges(nodeId));
      for(Edge edge in edges){
        nodes.add(edge.targetNodeId);
      }
    }
    return null;
  }

  @override
  String? checkAddEdge(Graph graph, String fromId, String toId, bool directed) {
    String? message = super.checkAddEdge(graph, fromId, toId, directed);
    if(message != null) return message;
    if(!directed) return "Non-directed edges aren't allowed in Johnson";
    return null;
  }

  @override
  List<String> validateGraph(Graph graph) {
    List<String> messages = [];
    List<Edge> edges = graph.edges.values.toList();
    for(Edge edge in edges){
      if(!edge.directed){
        messages.add("Non-directed edges aren't allowed in Johnson");
        break;
      }
      if(edge.sourceNodeId == edge.targetNodeId){
        messages.add("Self loop aren't allowed in Johnson");
        break;
      }
    }
    return messages;
  }
}