import 'package:graph_maker_app_2/algorithms/hungarian_assignment.dart';
import 'package:graph_maker_app_2/models/assignment_overlay.dart';
import 'package:graph_maker_app_2/models/matrix_data.dart';
import 'package:graph_maker_app_2/models/node.dart';

class AssignmentService {
  final MatrixData matrix;
  final bool mode;

  AssignmentService({required this.matrix, required this.mode});

  List<List<double>> prepare(){
    double m = 1;
    for(int i = 0; i < matrix.matrix.length; i++){
      for(int j = 0; j < matrix.matrix[0].length; j++){
        m += (matrix.matrix[i][j] < 0? -matrix.matrix[i][j] : matrix.matrix[i][j]);
      }
    }

    List<List<double>> costMatrix = List.generate(matrix.matrix.length, (_) => List.filled(matrix.matrix[0].length, 0.0));

    for(int i = 0; i < matrix.matrix.length; i++){
      for(int j = 0; j < matrix.matrix[0].length; j++){
        if(matrix.hasEdge[i][j]) {
          costMatrix[i][j] = matrix.matrix[i][j];
        }else{
          costMatrix[i][j] = (mode? m : -m);
        }
      }
    }
    return costMatrix;
  }

  HungarianResult run(){
    HungarianResult result = HungarianAssignment().solve(prepare(), mode);
    double total = 0;
    for(int i = 0; i < result.assignment.length; i++){
      int j = result.assignment[i];
      if(j != -1 && matrix.hasEdge[i][j]) total += matrix.matrix[i][j];
    }
    result.totalCost = total;
    return result;
  }

  AssignmentOverlay buildOverlay(HungarianResult result){
    final int rows = result.rows;
    final int cols = result.cols;
    final int n = result.fullAssignment.length;
    if(n == 0) return AssignmentOverlay();

    final bool dummyRows = cols > rows;
    final List<Node> side = dummyRows ? matrix.rowHeaders : matrix.colHeaders;
    final List<GhostNode> ghosts = placeGhosts(side, n - (dummyRows ? rows : cols));

    String rowId(int i) => i < rows ? matrix.rowHeaders[i].id : ghosts[i - rows].id;
    String colId(int j) => j < cols ? matrix.colHeaders[j].id : ghosts[j - cols].id;
    String rowName(int i) => i < rows ? matrix.rowHeaders[i].name : ghosts[i - rows].name;
    String colName(int j) => j < cols ? matrix.colHeaders[j].name : ghosts[j - cols].name;

    List<GhostEdge> edges = [];
    List<AssignmentPair> pairs = [];
    Set<String> highlighted = {};

    for(int k = 0; k < ghosts.length; k++){
      final GhostNode ghost = ghosts[k];
      if(dummyRows){
        for(int j = 0; j < cols; j++){
          edges.add(GhostEdge(ghost.id, colId(j), 0, assigned: result.fullAssignment[rows + k] == j));
        }
      }else{
        for(int i = 0; i < rows; i++){
          edges.add(GhostEdge(rowId(i), ghost.id, 0, assigned: result.fullAssignment[i] == cols + k));
        }
      }
    }

    for(int i = 0; i < n; i++){
      final int j = result.fullAssignment[i];
      if(j < 0) continue;
      if(i >= rows || j >= cols){
        pairs.add(AssignmentPair(rowName(i), colName(j), 0, AssignmentPairKind.dummy));
      }else if(matrix.hasEdge[i][j]){
        pairs.add(AssignmentPair(rowName(i), colName(j), matrix.matrix[i][j], AssignmentPairKind.real));
        highlighted.add(matrix.edgeIds[i][j]);
      }else{
        pairs.add(AssignmentPair(rowName(i), colName(j), 0, AssignmentPairKind.noEdge));
        edges.add(GhostEdge(rowId(i), colId(j), 0, assigned: true, noEdge: true));
      }
    }

    return AssignmentOverlay(nodes: ghosts, edges: edges, pairs: pairs, highlightedEdgeIds: highlighted);
  }

  static MatrixData padToSquare(MatrixData data){
    final int rows = data.rowHeaders.length;
    final int cols = data.colHeaders.length;
    final int n = rows > cols ? rows : cols;
    if(rows == cols) return data;

    final double radius = data.nodes.isEmpty ? 30 : data.nodes.first.radius;
    List<Node> dummies(int count) =>
        List.generate(count, (k) => Node("dummy_$k", "D${k + 1}", 0, 0, radius));
    final rowHeaders = [...data.rowHeaders, ...dummies(n - rows)];
    final colHeaders = [...data.colHeaders, ...dummies(n - cols)];

    T cell<T>(List<List<T>> m, int i, int j, T empty) => (i < rows && j < cols) ? m[i][j] : empty;

    return MatrixData(
      nodes: data.nodes,
      rowHeaders: rowHeaders,
      colHeaders: colHeaders,
      matrix: List.generate(n, (i) => List.generate(n, (j) => cell(data.matrix, i, j, 0.0))),
      hasEdge: List.generate(n, (i) => List.generate(n, (j) => cell(data.hasEdge, i, j, false))),
      edgeIds: List.generate(n, (i) => List.generate(n, (j) => cell(data.edgeIds, i, j, ""))),
      rowSum: List.generate(n, (i) => i < rows ? data.rowSum[i] : 0.0),
      colSum: List.generate(n, (j) => j < cols ? data.colSum[j] : 0.0),
      rowDegree: List.generate(n, (i) => i < rows ? data.rowDegree[i] : 0),
      colDegree: List.generate(n, (j) => j < cols ? data.colDegree[j] : 0),
    );
  }

  static bool isDummy(Node node) => node.id.startsWith("dummy_");

  List<GhostNode> placeGhosts(List<Node> side, int count){
    if(count <= 0 || side.isEmpty) return [];
    final double radius = side.first.radius;
    final double minDistance = 2 * radius + 3;
    final double step = minDistance + 12;

    Node lowest = side.first;
    for(final node in side){
      if(node.y > lowest.y) lowest = node;
    }

    bool isFree(double x, double y, List<GhostNode> placed){
      for(final node in matrix.nodes){
        final dx = node.x - x, dy = node.y - y;
        if(dx * dx + dy * dy <= minDistance * minDistance) return false;
      }
      for(final ghost in placed){
        final dx = ghost.x - x, dy = ghost.y - y;
        if(dx * dx + dy * dy <= minDistance * minDistance) return false;
      }
      return true;
    }

    List<GhostNode> ghosts = [];
    double y = lowest.y;
    for(int k = 0; k < count; k++){
      do {
        y += step;
      } while(!isFree(lowest.x, y, ghosts));
      ghosts.add(GhostNode("dummy_$k", "D${k + 1}", lowest.x, y, radius));
    }
    return ghosts;
  }
}