import 'package:graph_maker_app_2/algorithms/hungarian_assignment.dart';
import 'package:graph_maker_app_2/models/matrix_data.dart';

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
}