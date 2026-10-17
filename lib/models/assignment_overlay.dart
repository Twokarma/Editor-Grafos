
enum AssignmentPairKind { real, dummy, noEdge }

class AssignmentPair {
  final String sourceName;
  final String targetName;
  final double weight;
  final AssignmentPairKind kind;

  AssignmentPair(this.sourceName, this.targetName, this.weight, this.kind);
}

class GhostNode {
  final String id;
  final String name;
  final double x;
  final double y;
  final double radius;

  GhostNode(this.id, this.name, this.x, this.y, this.radius);
}

class GhostEdge {
  final String sourceId;
  final String targetId;
  final double weight;
  final bool assigned;
  final bool noEdge;

  GhostEdge(this.sourceId, this.targetId, this.weight, {this.assigned = false, this.noEdge = false});
}

class AssignmentOverlay {
  final List<GhostNode> nodes;
  final List<GhostEdge> edges;
  final List<AssignmentPair> pairs;
  final Set<String> highlightedEdgeIds;

  AssignmentOverlay({
    this.nodes = const [],
    this.edges = const [],
    this.pairs = const [],
    this.highlightedEdgeIds = const {},
  });
}
