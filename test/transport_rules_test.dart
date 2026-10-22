import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/transport_rules.dart';

void main() {
  final rules = TransportRules();
  late Graph graph; // nodos n0 (A), n1 (B), n2 (C), separados entre sí

  setUp(() {
    graph = Graph();
    graph.addNode(0, 0);
    graph.addNode(200, 0);
    graph.addNode(400, 0);
  });

  test('fuerza aristas dirigidas', () {
    expect(rules.forcesDirected(), isTrue);
    expect(rules.checkAddEdge(graph, 'n0', 'n1', false), isNotNull);
    expect(rules.checkAddEdge(graph, 'n0', 'n1', true), isNull);
  });

  test('no permite lazos', () {
    expect(rules.checkEdgeEndpoints(graph, 'n0', 'n0'), isNotNull);
  });

  test('un destino no puede pasar a ser origen', () {
    graph.addEdge('n0', 'n1', 5);
    expect(rules.checkEdgeEndpoints(graph, 'n1', 'n2'), contains('already a destination'));
  });

  test('un origen no puede pasar a ser destino', () {
    graph.addEdge('n0', 'n1', 5);
    expect(rules.checkEdgeEndpoints(graph, 'n2', 'n0'), contains('already a source'));
  });

  test('un grafo origen -> destino es válido', () {
    graph.addEdge('n0', 'n1', 5);
    graph.addEdge('n0', 'n2', 7);
    expect(rules.validateGraph(graph), isEmpty);
  });

  test('validateGraph detecta un nodo que es origen y destino a la vez', () {
    graph.addEdge('n0', 'n1', 5);
    graph.addEdge('n1', 'n2', 7);
    expect(rules.validateGraph(graph), isNotEmpty);
  });

  test('validateGraph rechaza aristas no dirigidas', () {
    graph.addEdge('n0', 'n1', 5, directed: false);
    expect(rules.validateGraph(graph), isNotEmpty);
  });
}
