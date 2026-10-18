import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/widgets/overlays/highlight_overlay.dart';

class JohnsonOverlay extends HighlightOverlay{
  final Map<String, double> holgura;

  new(super.highlightedEdges, super.highlightColor, this.holgura);

  @override
  String edgeLabelSuffix(Edge edge) {
    if(!holgura.containsKey(edge.id)) {
      return super.edgeLabelSuffix(edge);
    }
    return "  h = ${holgura[edge.id].toString()}";
  }
}