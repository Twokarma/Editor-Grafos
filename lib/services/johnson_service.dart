import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/models/node.dart';

enum Objective {max, min}
class JohnsonService {
  List<Node> nodes;
  List<Edge> edges;
  Objective objective = Objective.max;
  late int n;
  double inf = double.infinity;
  Map<String, int> index = {};
  late String nodeFrom;
  late String nodeTo;
  late JohnsonResult1 result;

  JohnsonService({required this.nodes, required this.edges, required this.nodeFrom, required this.nodeTo});

  JohnsonData prepare(){
    JohnsonData data = JohnsonData();

    Set<String> nodesFiltered = {};
    Set<String> nodesFrom = {};
    Set<String> nodesTo = {};
    for(Edge edge in edges){
      nodesFiltered.add(edge.sourceNodeId);
      nodesFiltered.add(edge.targetNodeId);
      nodesFrom.add(edge.sourceNodeId);
      nodesTo.add(edge.targetNodeId);
    }

    nodes.removeWhere((node) => !nodesFiltered.contains(node.id));
    n = nodes.length;
    nodeFrom = nodesFrom.difference(nodesTo).first;
    nodeTo = nodesTo.difference(nodesFrom).first;

    List<List<double>> cost = List.generate(n, (i) {
     return List.generate(n, (j) {
       if(i == j) return 0.0;
       return inf;
     });
    });
    List<List<String>> edgesIds = List.generate(n, (_) => List.filled(n, ""));


    for(int i = 0; i < n; i++){
      index[nodes[i].id] = i;
    }

    for(Edge edge in edges){
      int i = index[edge.sourceNodeId]!;
      int j = index[edge.targetNodeId]!;
      cost[i][j] = edge.weight;
      edgesIds[i][j] = edge.id;
    }
    data.cost = cost;
    data.edgesIds = edgesIds;

    return data;
  }

  JohnsonResult1 run(){
    JohnsonData data = prepare();
    JohnsonResult1 result = Johnson1().solve(data.cost, data.edgesIds, nodes);

    for(int i = 0; i < n; i++){
      for(int j = 0; j < n; j++){
        if(result.distanceMax[i][j] != inf)result.distanceMax[i][j] *= -1;
      }
    }

    double t = result.distanceMax[index[nodeFrom]!][index[nodeTo]!];
    if(t != inf){
      for(Node node in nodes){
        int i = index[node.id]!;
        result.backwards[node.id] = t - result.distanceMax[i][index[nodeTo]!];
      }

      for(Edge edge in edges){
        int j = index[edge.sourceNodeId]!;
        double? a1 = result.distanceMax[index[nodeFrom]!][j];
        double? b2 = result.backwards[edge.targetNodeId]!;
        if(a1 == inf || b2 == inf) continue;
        double h = b2 - a1 - edge.weight;
        result.holgura[edge.id] = h;
      }
    }

    this.result = result;
    return result;
  }

  Set<String> path(Objective obj, {String? from, String? to}){
    Set<String> edgePath = {};
    Map<String, Edge> edgesMap = {
      for(Edge edge in edges) edge.id: edge
    };
    from ??= nodeFrom;
    to ??= nodeTo;

    if(from == to) return {};

    List<List<double>> distance = obj == Objective.max? result.distanceMax : result.distanceMin;
    List<List<String>> edgesIds = obj == Objective.max? result.bestEdgeIdsMax : result.bestEdgeIdsMIn;
    int i = index[from]!;
    int j = index[to]!;
    Edge edge = edgesMap[edgesIds[i][j]]!;
    edgePath.add(edge.id);
    while(edge.sourceNodeId != from){
      if(distance[i][j] == inf) return {};
      j = index[edge.sourceNodeId]!;
      edge = edgesMap[edgesIds[i][j]]!;
      edgePath.add(edge.id);
    }
    edgePath.add(distance[index[from]!][index[to]!].toString());

    return edgePath;
  }
}

class JohnsonData{
  List<List<double>> cost = [];
  List<List<String>> edgesIds = [];
}