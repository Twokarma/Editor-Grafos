import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';

import '../models/assignment_overlay.dart';
import '../models/edge.dart';
import '../models/graph.dart';
import '../models/node.dart';
import '../theme/app_colors.dart';

class GraphPainter extends CustomPainter{
  final Map<String, Node> nodes;
  final Map<String, Edge> edges;
  final Set<String> highlightedEdgeIds;
  final Color highlightedColor;
  final Map<String, double> holgura;
  final String dragSourceId;
  final Offset? dragCurrentPosition;
  final String? movingNodeId;
  final Offset? movingNodePosition;
  final AppViewport viewport;
  final List<GhostNode> ghostNodes;
  final List<GhostEdge> ghostEdges;


  GraphPainter({
    this.ghostNodes = const [],
    this.ghostEdges = const [],
    required this.nodes,
    required this.edges,
    this.highlightedEdgeIds = const {},
    this.highlightedColor = AppColors.assignmentEdge,
    this.holgura = const {},
    required this.dragSourceId,
    required this.dragCurrentPosition,
    this.movingNodeId,
    this.movingNodePosition,
    required this.viewport,
  });

  Offset _positionOf(Node node) {
    if (node.id == movingNodeId && movingNodePosition != null) {
      return movingNodePosition!;
    }
    return Offset(node.x, node.y);
  }

  static const double _arrowLength = 15;
  static const double _arrowWidth = 8;
  static const double _labelOffset = 14;
  static const double _parallelEdgeOffset = 7.5;
  static const double _labelGap = 8;

  void _drawArrowhead(Canvas canvas, Offset tip, double ux, double uy, Color color) {
    final backPoint = Offset(
      tip.dx - ux * _arrowLength,
      tip.dy - uy * _arrowLength,
    );
    final perpX = -uy;
    final perpY = ux;
    final leftPoint = Offset(
      backPoint.dx + perpX * _arrowWidth,
      backPoint.dy + perpY * _arrowWidth,
    );
    final rightPoint = Offset(
      backPoint.dx - perpX * _arrowWidth,
      backPoint.dy - perpY * _arrowWidth,
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  void _drawDirectedEdge(Canvas canvas, Offset sourcePos, Offset targetPos, double targetRadius, double ux, double uy, Color edgeColor, bool directed, double stroke) {
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = stroke;

    final tip = Offset(
      targetPos.dx - ux * targetRadius,
      targetPos.dy - uy * targetRadius,
    );

    canvas.drawLine(sourcePos, tip, paint);

    if (directed) {
      _drawArrowhead(canvas, tip, ux, uy, edgeColor);
    }
  }

  void _drawSelfLoop(Canvas canvas, Offset nodePos, double nodeRadius, Color edgeColor, double stroke) {
    final loopCenter = Offset(nodePos.dx + Graph.selfLoopCenterDistance(nodeRadius), nodePos.dy);

    final paint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(loopCenter, Graph.selfLoopRadius, paint);
  }

  static const double _dashLength = 8;
  static const double _dashGap = 6;

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final total = (to - from).distance;
    if (total == 0) return;
    final dir = (to - from) / total;
    for (double d = 0; d < total; d += _dashLength + _dashGap) {
      final end = min(d + _dashLength, total);
      canvas.drawLine(from + dir * d, from + dir * end, paint);
    }
  }

  void _drawGhostEdges(Canvas canvas) {
    final ghostById = {for (final g in ghostNodes) g.id: g};

    (Offset, double)? endpoint(String id) {
      final real = nodes[id];
      if (real != null) return (_positionOf(real), real.radius);
      final ghost = ghostById[id];
      if (ghost != null) return (Offset(ghost.x, ghost.y), ghost.radius);
      return null;
    }

    final ordered = [
      ...ghostEdges.where((e) => !e.assigned),
      ...ghostEdges.where((e) => e.assigned),
    ];

    for (final edge in ordered) {
      final source = endpoint(edge.sourceId);
      final target = endpoint(edge.targetId);
      if (source == null || target == null) continue;

      final sourcePos = source.$1;
      final targetPos = target.$1;
      final distance = (targetPos - sourcePos).distance;
      if (distance == 0) continue;
      final ux = (targetPos.dx - sourcePos.dx) / distance;
      final uy = (targetPos.dy - sourcePos.dy) / distance;
      final tip = Offset(targetPos.dx - ux * target.$2, targetPos.dy - uy * target.$2);

      final color = edge.noEdge
          ? AppColors.noEdgeAssignment
          : edge.assigned ? highlightedColor : AppColors.ghostEdge;
      final paint = Paint()
        ..color = color
        ..strokeWidth = edge.assigned ? 6.0 : 2.0;

      _drawDashedLine(canvas, sourcePos, tip, paint);
      _drawArrowhead(canvas, tip, ux, uy, color);

      final midX = (sourcePos.dx + tip.dx) / 2 - uy * _labelOffset;
      final midY = (sourcePos.dy + tip.dy) / 2 + ux * _labelOffset;
      final label = TextPainter(
        text: TextSpan(
          text: edge.noEdge ? "no edge" : "${edge.weight}",
          style: TextStyle(
            color: color,
            fontSize: edge.assigned ? 15 : 12,
            fontWeight: edge.assigned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(canvas, Offset(midX - label.width / 2, midY - label.height / 2));
    }
  }

  void _drawGhostNodes(Canvas canvas) {
    final border = Paint()
      ..color = AppColors.ghostNodeBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final ghost in ghostNodes) {
      final pos = Offset(ghost.x, ghost.y);
      canvas.drawCircle(pos, ghost.radius, Paint()..color = AppColors.ghostNode);

      const dashes = 16;
      const sweep = 2 * pi / dashes;
      final rect = Rect.fromCircle(center: pos, radius: ghost.radius);
      for (int i = 0; i < dashes; i++) {
        canvas.drawArc(rect, i * sweep, sweep * 0.6, false, border);
      }

      final label = TextPainter(
        text: TextSpan(
          text: ghost.name,
          style: const TextStyle(color: AppColors.darkNodeLabel, fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(canvas, Offset(pos.dx - label.width / 2, pos.dy - label.height / 2));
    }
  }



  @override
  void paint(Canvas canvas, Size size) {
    /*canvas.clipRect(Offset.zero & size);

    canvas.save();
    canvas.translate(viewport.offset.dx, viewport.offset.dy);
    canvas.scale(viewport.scale);

    Offset left = viewport.toWorld(Offset.zero);
    Offset right = viewport.toWorld(Offset(size.width, size.height));
    double spacing = viewport.scale < 0.5 ? 100.0 : 50.0;

    left = Offset((left.dx/spacing).floorToDouble(), (left.dy/spacing).floorToDouble()) * spacing;
    right = Offset((right.dx/spacing).floorToDouble(), (right.dy/spacing).floorToDouble()) * spacing;
    Paint gridPaint = Paint()
      ..color = AppColors.gridColor
      ..strokeWidth = 0
      ..strokeCap = StrokeCap.butt;

    for(double x = left.dx; x <= right.dx; x += spacing){
      canvas.drawLine(Offset(x, left.dy), Offset(x, right.dy), gridPaint);
    }
    for(double y = left.dy; y <= right.dy; y += spacing){
      canvas.drawLine(Offset(left.dx, y), Offset(right.dx, y), gridPaint);
    }*/

    final paint = Paint()
      ..color = AppColors.previewEdge
      ..strokeWidth = 5;

    edges.forEach((id, edge){
      Node? sourceNode = nodes[edge.sourceNodeId];
      Node? targetNode = nodes[edge.targetNodeId];
      if (sourceNode == null || targetNode == null) return;

      if (edge.isLoop()) {
        final pos = _positionOf(sourceNode);
        final edgeColor = highlightedEdgeIds.contains(id)? highlightedColor : AppColors.selfLoopEdge;
        final stroke = highlightedEdgeIds.contains(id)? 8.0 : 5.0;
        _drawSelfLoop(canvas, pos, sourceNode.radius, edgeColor, stroke);

        final loopCenter = Offset(pos.dx + Graph.selfLoopCenterDistance(sourceNode.radius), pos.dy);
        final label = TextPainter(
          text: TextSpan(
              text: edge.weight.toString(),
              style: TextStyle(
                color: edgeColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )
          ),
          textDirection: TextDirection.ltr,
        );
        label.layout();
        label.paint(canvas, Offset(loopCenter.dx - label.width / 2, loopCenter.dy + Graph.selfLoopRadius + 4));
        return;
      }

      final sourcePos = _positionOf(sourceNode);
      final targetPos = _positionOf(targetNode);

      final dx = targetPos.dx - sourcePos.dx;
      final dy = targetPos.dy - sourcePos.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance == 0) return;

      final ux = dx / distance;
      final uy = dy / distance;
      final edgeColor = highlightedEdgeIds.contains(id)? highlightedColor : dx >= 0 ? AppColors.leftRightEdge : AppColors.rightLeftEdge;
      final stroke = highlightedEdgeIds.contains(id)? 8.0 : 5.0;

      final perpX = -uy;
      final perpY = ux;
      final hasMirror = edges.values.any((e) =>
      e.sourceNodeId == edge.targetNodeId && e.targetNodeId == edge.sourceNodeId);
      final lineOffset = hasMirror ? _parallelEdgeOffset : 0.0;

      final offsetSourcePos = Offset(sourcePos.dx + perpX * lineOffset, sourcePos.dy + perpY * lineOffset);
      final offsetTargetPos = Offset(targetPos.dx + perpX * lineOffset, targetPos.dy + perpY * lineOffset);

      _drawDirectedEdge(canvas, offsetSourcePos, offsetTargetPos, targetNode.radius, ux, uy, edgeColor, edge.directed, stroke);

      final midX = (offsetSourcePos.dx + offsetTargetPos.dx) / 2 + perpX * _labelOffset;
      final midY = (offsetSourcePos.dy + offsetTargetPos.dy) / 2 + perpY * _labelOffset;

      String h = holgura.containsKey(edge.id)? " h = ${holgura[edge.id]}" : "";
      final label = TextPainter(
        text: TextSpan(
            text: "${edge.weight}$h",
            style: TextStyle(
              color: edgeColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(canvas, Offset(midX - label.width / 2, midY - label.height / 2));
    });

    _drawGhostEdges(canvas);

    if(dragSourceId != "" && dragSourceId != "tooClose" && dragCurrentPosition != null) {
      final dragSource = nodes[dragSourceId];
      if (dragSource != null) {
        canvas.drawLine(_positionOf(dragSource), dragCurrentPosition!, paint);
      }
    }

    nodes.forEach((id, node){
      final pos = _positionOf(node);
      final nodeColor = Color(node.color);
      canvas.drawCircle(pos, node.radius, Paint()..color = nodeColor);

      final labelColor = nodeColor.computeLuminance() > 0.5 ? AppColors.lightNodeLabel : AppColors.darkNodeLabel;
      final label = TextPainter(
        text: TextSpan(
            text: node.name,
            style: TextStyle(
              color: labelColor,
              fontSize: 15,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(canvas, Offset(pos.dx-10, pos.dy-10));
    });

    _drawGhostNodes(canvas);

    //canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}
