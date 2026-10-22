import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/overlays/highlight_overlay.dart';

import '../../models/node.dart';
import 'canvas_overlay.dart';

class JohnsonOverlay extends HighlightOverlay{
  final JohnsonResult1 result;
  final Map<String, Node> johnsonNodes = {};
  final yCircleOffset = -0.15;

  new(super.highlightedEdges, super.highlightColor, this.result, List<Node> johnsonNodes){
    for(Node node in johnsonNodes) {this.johnsonNodes[node.id] = node;}
  }

  @override
  String edgeLabelSuffix(Edge edge) {
    if(!result.holgura.containsKey(edge.id)) {
      return super.edgeLabelSuffix(edge);
    }
    return " | h = ${result.holgura[edge.id].toString()}";
  }

  @override
  void paintAfterNodes(OverlayPaintContext paintCtx) {
    final nodes = johnsonNodes.values.toList();
    final canvas = paintCtx.canvas;
    final paint = Paint()
    ..strokeWidth = 3
    ..color = AppColors.johnsonNodeLines;

    for(int i = 0; i < nodes.length; i++){
      Node node = nodes[i];
      Offset center = paintCtx.positionOf(node);
      double y = node.radius * yCircleOffset + center.dy;
      canvas.drawLine(Offset(_computeCircleXOffset(center, y, node.radius, 1), y), Offset(_computeCircleXOffset(center, y, node.radius, -1), y), paint);
      canvas.drawLine(Offset(center.dx, y), Offset(center.dx, center.dy + node.radius), paint);

      final nodeColor = Color(node.color);
      final labelColor = nodeColor.computeLuminance() > 0.5 ? AppColors.lightNodeLabel : AppColors.darkNodeLabel;
      final latest = TextPainter(
        text: TextSpan(
            text: result.distanceMax[0][i].toString(),
            style: TextStyle(
              color: labelColor,
              fontSize: 15,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      latest.layout();
      latest.paint(canvas, Offset(center.dx - node.radius/2 - latest.width/2, center.dy));

      final earliest = TextPainter(
        text: TextSpan(
            text: result.backwards[node.id].toString(),
            style: TextStyle(
              color: labelColor,
              fontSize: 15,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      earliest.layout();
      earliest.paint(canvas, Offset(center.dx + node.radius/2 - latest.width/2, center.dy));
    }
  }

  double _computeCircleXOffset(Offset center, double y, double radius, double s){
    double yk = y-center.dy;
    if(yk == radius) yk = 0;
    double root2 = sqrt((radius * radius) - (yk * yk)) * s;
    return root2 + center.dx;
  }

  @override
  Offset namePosition(Node node) {
    if(!johnsonNodes.containsKey(node.id)) return super.namePosition(node);
    return Offset(0.0, node.radius * yCircleOffset * 3);
  }
}