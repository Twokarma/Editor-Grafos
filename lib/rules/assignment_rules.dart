import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

import '../models/graph.dart';

class AssignmentRules extends GraphRules{
  @override
  bool forcesDirected() {
    return true;
  }

  @override
  String? checkEdgeEndpoints(Graph graph, String fromId, String toId) {
    String? message = super.checkEdgeEndpoints(graph, fromId, toId);
    if(message != null) return message;

    List<Edge> edges = graph.edges.values.toList();
    if(fromId == toId) return "Self loops aren't allowed in Assignment";
    for(Edge edge in edges){
      if(edge.targetNodeId == fromId) return "${graph.nodes[fromId]!.name} is already a target";
      if(edge.sourceNodeId == toId) return "${graph.nodes[toId]!.name} is already a source";
    }

    return null;
  }

  @override
  String? checkAddEdge(Graph graph, String fromId, String toId, bool directed) {
    String? message = super.checkAddEdge(graph, fromId, toId, directed);
    if(message != null) return message;
    if(!directed) return "Non-directed edges aren't allowed in Assignment";
    return null;
  }

  @override
  List<String> validateGraph(Graph graph) {
    List<String> messages = [];
    List<Edge> edges = graph.edges.values.toList();
    Set<String> sourcesIds = {};
    Set<String> targetIds = {};
    for(Edge edge in edges){
      if(!edge.directed){
        messages.add("Non-directed edges aren't allowed in Assignment");
        break;
      }
      if(edge.sourceNodeId == edge.targetNodeId){
        messages.add("Self loops aren't allowed in Assignment");
        break;
      }
      if(sourcesIds.contains(edge.targetNodeId)){
        messages.add("Node ${graph.nodes[edge.targetNodeId]!.name} can't have incoming and outgoing edges");
        break;
      }else{
        targetIds.add(edge.targetNodeId);
      }
      if(targetIds.contains(edge.sourceNodeId)){
        messages.add("Node ${graph.nodes[edge.sourceNodeId]!.name} can't have incoming and outgoing edges");
        break;
      }else{
        sourcesIds.add(edge.sourceNodeId);
      }
    }
    return messages;
  }
}