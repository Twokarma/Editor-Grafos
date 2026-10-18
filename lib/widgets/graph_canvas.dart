import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graph_maker_app_2/widgets/dialogs/edit_edge_dialog.dart';
import 'package:graph_maker_app_2/widgets/overlays/canvas_overlay.dart';
import 'package:provider/provider.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';

import '../models/assignment_overlay.dart';
import '../providers/graph_provider.dart';
import 'dialogs/edge_dialog.dart';
import 'dialogs/edit_node_dialog.dart';
import 'graph_painter.dart';
import '../theme/app_colors.dart';

class GraphWidget extends StatefulWidget{
  final CanvasOverlay canvasOverlay;
  const GraphWidget({
    super.key,
    this.canvasOverlay = const DefaultOverlay(),
  });

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  AppViewport viewport = AppViewport();
  String sourceNode = "";
  Offset? currentDragPosition;

  static const Duration _holdDuration = Duration(milliseconds: 500);
  Timer? _holdTimer;
  bool _panMoved = false;
  bool _suppressNextTap = false;

  bool _isMovingNode = false;
  String _movingNodeId = "";
  Offset? _movingNodeCurrentPosition;

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();

    return GestureDetector(

      onPanDown: (details) {
        _panMoved = false;
        _suppressNextTap = false;
        _cancelHold();

        final provider = context.read<GraphProvider>();
        String tap = provider.findNodeAt(details.localPosition.dx, details.localPosition.dy);
        if (tap == "") {
          setState(() => sourceNode = "");
          return;
        }

        final nodeId = tap;
        setState(() => sourceNode = tap);
        _holdTimer = Timer(_holdDuration, () {
          if (_panMoved) return;
          final node = provider.graphGetter().nodes[nodeId];
          if (node == null) return;

          HapticFeedback.lightImpact();
          _suppressNextTap = true;
          setState(() {
            _isMovingNode = true;
            _movingNodeId = nodeId;
            _movingNodeCurrentPosition = Offset(node.x, node.y);
            sourceNode = "";
          });
        });
      },

      onPanStart: (details) {
        _panMoved = true;
        if (_isMovingNode) return;
      },

      onPanUpdate: (details) {
        if (_isMovingNode) {
          setState(() {
            _movingNodeCurrentPosition = details.localPosition;
          });
          return;
        }
        if(sourceNode != "") {
          setState(() {
            currentDragPosition = details.localPosition;
          });
        }
      },

      onPanEnd: (details) {
        _cancelHold();

        if (_isMovingNode) {
          final provider = context.read<GraphProvider>();
          final target = _movingNodeCurrentPosition!;
          final moved = provider.moveNode(_movingNodeId, target.dx, target.dy);
          if (moved != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(moved)),
            );
          }
          setState(() {
            _isMovingNode = false;
            _movingNodeId = "";
            _movingNodeCurrentPosition = null;
            sourceNode = "";
          });
          return;
        }

        if (sourceNode == "" || currentDragPosition == null) return;

        final provider = context.read<GraphProvider>();
        String tap = provider.findNodeAt(currentDragPosition!.dx, currentDragPosition!.dy);

        if (tap != "") {
          String? message = provider.checkEdgeEndpoints(sourceNode, tap);

          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          } else {
            showEdgeDialog(context, provider, source: sourceNode, target: tap);
          }
        }

        setState(() {
          sourceNode = "";
          currentDragPosition = null;
        });
      },

      onPanCancel: () {
        _cancelHold();
        setState(() {
          _isMovingNode = false;
          _movingNodeId = "";
          _movingNodeCurrentPosition = null;
          sourceNode = "";
          currentDragPosition = null;
        });
      },

      onDoubleTapDown: ((details) {
        final graphProvider = context.read<GraphProvider>();
        String tap = graphProvider.findNodeAt(details.localPosition.dx, details.localPosition.dy);
        if(tap != "") {
          String? message = graphProvider.removeNode(tap);
          if(message != null){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        } else {
          String edgeTap = graphProvider.findEdgeAt(details.localPosition.dx, details.localPosition.dy);
          if(edgeTap != ""){
            String? message = graphProvider.removeEdge(edgeTap);
            if(message != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          }
        }
      }),

      onTapUp: ((details) {
        if (_suppressNextTap) {
          _suppressNextTap = false;
          return;
        }

        final graphProvider = context.read<GraphProvider>();
        String tap = graphProvider.findNodeAt(details.localPosition.dx, details.localPosition.dy);


        if(tap.startsWith("n")){
          showEditNodeDialog(context, graphProvider, tap);
        } else {
          tap = graphProvider.findEdgeAt(details.localPosition.dx, details.localPosition.dy);
          if(tap.startsWith("e")) {
            showEditEdgeDialog(context, graphProvider, tap);
          }
        }

        if(tap == ""){
          String? message = graphProvider.addNode(details.localPosition.dx, details.localPosition.dy);
          if(message != null){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      }),

      child: SizedBox.expand(
        child: CustomPaint(
          painter: GraphPainter(
            nodes: graphProvider.graphGetter().nodes,
            edges: graphProvider.graphGetter().edges,
            dragSourceId: sourceNode,
            dragCurrentPosition: currentDragPosition,
            movingNodeId: _isMovingNode ? _movingNodeId : null,
            movingNodePosition: _isMovingNode ? _movingNodeCurrentPosition : null,
            canvasOverlay: widget.canvasOverlay,
            viewport: viewport,
          ),
        ),
      ),
    );

  }
}
