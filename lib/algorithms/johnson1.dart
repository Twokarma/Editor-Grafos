
import 'package:graph_maker_app_2/models/node.dart';

class Johnson1 {
  late int n;
  Map<String, int> index = {};

  JohnsonResult1 solve(List<List<double>> cost, List<List<String>> edgeIds, List<Node> nodes){
    n = cost.length;
    JohnsonResult1 result = JohnsonResult1();

    for(int i = 0; i < n; i++){
      index[nodes[i].id] = i;
    }

    List<List<double>> negativeCost = negate(cost);
    JohnsonResult1 max = floydWarshall(negativeCost, nodes, edgeIds);
    JohnsonResult1 min = floydWarshall(cost, nodes, edgeIds);

    result = max;
    result.distanceMin = min.distanceMax;
    result.bestEdgeIdsMIn = min.bestEdgeIdsMax;
    return result;
  }

  JohnsonResult1 floydWarshall(List<List<double>> cost, List<Node> nodes, List<List<String>> edgeIds){
    JohnsonResult1 result = JohnsonResult1();
    int k;
    double inf = double.infinity;

    List<List<double>> distance = List.generate(n, (i){
      return List.generate((n), (j){
        return cost[i][j];
      });
    });
    List<List<String>> bestEdgeIds = List.generate(n, (i){
      return List.generate((n), (j){
        return edgeIds[i][j];
      });
    });


    for(Node node in nodes){
      k = index[node.id]!;
      for(int i = 0; i < n; i++){
        if(distance[i][k] == inf || i == k) continue;
        for(int j = 0; j < n; j++){
          if(distance[i][k] + distance[k][j] < distance[i][j]){
            distance[i][j] = distance[i][k] + distance[k][j];
            bestEdgeIds[i][j] = bestEdgeIds[k][j];
          }
        }
      }
    }
    result.distanceMax = distance;
    result.bestEdgeIdsMax = bestEdgeIds;

    return result;
  }

  List<List<double>> negate(List<List<double>> matrix){
    return List.generate(n, (i) {
      return List.generate(n, (j) {
        if(matrix[i][j] == double.infinity) return matrix[i][j];
        return -matrix[i][j];
      });
    });
  }

}

class JohnsonResult1{
  List<List<double>> distanceMax = [];
  List<List<String>> bestEdgeIdsMax = [];
  List<List<double>> distanceMin = [];
  List<List<String>> bestEdgeIdsMIn = [];
  Map<String, double> backwards = {};
  Map<String, double> holgura = {};
}