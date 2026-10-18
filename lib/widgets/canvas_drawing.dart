import 'dart:math';
import 'dart:ui';

import '../models/graph.dart';

class Draw {
  static const double arrowLength = 15;
  static const double arrowWidth = 8;
  static const double labelOffset = 14;
  static const double dashLength = 8;
  static const double dashGap = 6;


  static void drawArrowhead(Canvas canvas, Offset tip, double ux, double uy, Color color) {
    final backPoint = Offset(
      tip.dx - ux * arrowLength,
      tip.dy - uy * arrowLength,
    );
    final perpX = -uy;
    final perpY = ux;
    final leftPoint = Offset(
      backPoint.dx + perpX * arrowWidth,
      backPoint.dy + perpY * arrowWidth,
    );
    final rightPoint = Offset(
      backPoint.dx - perpX * arrowWidth,
      backPoint.dy - perpY * arrowWidth,
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  static void drawDirectedEdge(Canvas canvas, Offset sourcePos, Offset targetPos, double targetRadius, double ux, double uy, Color edgeColor, bool directed, double stroke) {
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = stroke;

    final tip = Offset(
      targetPos.dx - ux * targetRadius,
      targetPos.dy - uy * targetRadius,
    );

    canvas.drawLine(sourcePos, tip, paint);

    if (directed) {
      drawArrowhead(canvas, tip, ux, uy, edgeColor);
    }
  }

  static void drawSelfLoop(Canvas canvas, Offset nodePos, double nodeRadius, Color edgeColor, double stroke) {
    final loopCenter = Offset(nodePos.dx + Graph.selfLoopCenterDistance(nodeRadius), nodePos.dy);

    final paint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(loopCenter, Graph.selfLoopRadius, paint);
  }

  static void drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    for (double d = 0; d < total; d += dashLength + dashGap) {
      final end = min(d + dashLength, total);
      canvas.drawLine(from + dir * d, from + dir * end, paint);
    }
  }
}