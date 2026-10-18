import 'dart:ui';

import 'package:graph_maker_app_2/widgets/overlays/canvas_overlay.dart';

import '../../models/edge.dart';

class HighlightOverlay extends CanvasOverlay{
  final Set<String> highlightedEdges;
  final Color highlightColor;

  const HighlightOverlay(this.highlightedEdges, this.highlightColor);

  @override
  Color? edgeColor(Edge edge) {
    if(!highlightedEdges.contains(edge.id)) {
      return super.edgeColor(edge);
    }
    return highlightColor;
  }

  @override
  double? edgeStroke(Edge edge) {
    if(!highlightedEdges.contains(edge.id)) {
      return super.edgeStroke(edge);
    }
    return 8;
  }
}