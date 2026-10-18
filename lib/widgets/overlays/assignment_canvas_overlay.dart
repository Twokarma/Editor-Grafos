import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/assignment_overlay.dart';
import 'package:graph_maker_app_2/widgets/overlays/highlight_overlay.dart';

import '../../theme/app_colors.dart';
import '../canvas_drawing.dart';
import 'canvas_overlay.dart';

class AssignmentCanvasOverlay extends HighlightOverlay{
  List<GhostNode> ghostNodes;
  List<GhostEdge> ghostEdges;

  new(super.highlightedEdges, super.highlightColor, this.ghostNodes, this.ghostEdges  );

  @override
  void paintAfterEdges(OverlayPaintContext paintCtx) {
    final ghostById = {for (final g in ghostNodes) g.id: g};

    (Offset, double)? endpoint(String id) {
      final real = paintCtx.nodes[id];
      if (real != null) return (paintCtx.positionOf(real), real.radius);
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
          : edge.assigned ? highlightColor : AppColors.ghostEdge;
      final paint = Paint()
        ..color = color
        ..strokeWidth = edge.assigned ? 6.0 : 2.0;

      Draw.drawDashedLine(paintCtx.canvas, sourcePos, tip, paint);
      Draw.drawArrowhead(paintCtx.canvas, tip, ux, uy, color);

      final midX = (sourcePos.dx + tip.dx) / 2 - uy * Draw.labelOffset;
      final midY = (sourcePos.dy + tip.dy) / 2 + ux * Draw.labelOffset;
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
      label.paint(paintCtx.canvas, Offset(midX - label.width / 2, midY - label.height / 2));
    }
  }

  @override
  void paintAfterNodes(OverlayPaintContext paintCtx) {
    final border = Paint()
      ..color = AppColors.ghostNodeBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final ghost in ghostNodes) {
      final pos = Offset(ghost.x, ghost.y);
      paintCtx.canvas.drawCircle(pos, ghost.radius, Paint()..color = AppColors.ghostNode);

      const dashes = 16;
      const sweep = 2 * pi / dashes;
      final rect = Rect.fromCircle(center: pos, radius: ghost.radius);
      for (int i = 0; i < dashes; i++) {
        paintCtx.canvas.drawArc(rect, i * sweep, sweep * 0.6, false, border);
      }

      final label = TextPainter(
        text: TextSpan(
          text: ghost.name,
          style: const TextStyle(color: AppColors.darkNodeLabel, fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      label.paint(paintCtx.canvas, Offset(pos.dx - label.width / 2, pos.dy - label.height / 2));
    }
  }
}