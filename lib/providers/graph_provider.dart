import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/services/graph_storage_service.dart';

import '../models/edge.dart';
import '../models/matrix_data.dart';

class GraphProvider extends ChangeNotifier{
  Graph _graph = Graph();
  final GraphStorageService _storage = GraphStorageService();
  static const int _maxHistory = 20;
  final List<Graph> _history = [];
  final GraphRules rules;

  GraphProvider({Graph? initialGraph, GraphRules? graphRules}) : _graph = initialGraph?? Graph(), rules = graphRules?? DefaultRules();

  Graph graphGetter(){
    return _graph;
  }

  Graph snapshot(){
    return _graph.clone();
  }

  void replaceGraph(Graph newGraph){
    _pushHistory();
    _graph = newGraph.clone();
    notifyListeners();
  }

  String? addNode(double x,double y){
    String? message = rules.checkAddNode(_graph, x, y);
    if(message != null) return message;
    _pushHistory();
    _graph.addNode(x, y);
    notifyListeners();
    return null;
  }

  String? removeNode(String id){
    String? message = rules.checkRemoveNode(_graph, id);
    if(message != null) return message;
    _pushHistory();
    _graph.removeNode(id);
    notifyListeners();
    return null;
  }

  String? addEdge(String sourceNode,String targetNode, double weight, bool directed) {
    String? message = rules.checkAddEdge(_graph, sourceNode, targetNode, directed);
    if(message != null) return message;
    _pushHistory();
    Edge? reverse = _graph.findReverseEdge(sourceNode, targetNode);
    if(reverse != null && !directed) _graph.removeEdge(reverse.id);
    _graph.addEdge(sourceNode, targetNode, weight, directed: directed);
    notifyListeners();
    return null;
  }

  String? removeEdge(String id){
    String? message = rules.checkRemoveEdge(_graph, id);
    if(message != null) return message;
    _pushHistory();
    _graph.removeEdge(id);
    notifyListeners();
    return null;
  }

  void renameNode(String id, String newName){
    _pushHistory();
    _graph.renameNode(id, newName);
    notifyListeners();
  }

  void recolorNode(String id, int color){
    _pushHistory();
    _graph.recolorNode(id, color);
    notifyListeners();
  }

  void updateNode(String id,{String? newName, int? newColor}){
    _pushHistory();
    _graph.renameNode(id, newName!);
    _graph.recolorNode(id, newColor!);
    notifyListeners();
  }

  void updateEdgeWeight(String id, double newWeight) {
    _pushHistory();
    _graph.updateEdgeWeight(id, newWeight);
    notifyListeners();
  }

  String findEdgeAt(double x, double y) {
      return _graph.findEdgeAt(x, y);
  }

  Edge? findReverseEdge(String sourceNode, String targetNode){
    return _graph.findReverseEdge(sourceNode, targetNode);
  }

  String? checkEdgeEndpoints(String sourceId, String targetId){
    return rules.checkEdgeEndpoints(_graph, sourceId, targetId);
  }

  List<String> validateGraph(){
    return rules.validateGraph(_graph);
  }

  List<List<double>> adjacencyMatrix(MatrixData matrixData){
      return _graph.adjacencyMatrix(matrixData);
  }

  MatrixData buildMatrixData(){
      return _graph.buildMatrixData();
  }

  String graphSummaryJson() {
    return jsonEncode(_graph.toSummaryMap());
  }

  String? moveNode(String id, double x, double y){
    String? message = rules.checkMoveNode(_graph, id, x, y);
    if(message != null) return message;
    _pushHistory();
    _graph.moveNode(id, x, y);
    notifyListeners();
    return null;
  }

  String findNodeAt(double x, double y) {
    return _graph.findNodeAt(x, y);
  }

  bool edgeExists(String sourceNode, String tap) {
    return _graph.edgeExists(sourceNode, tap);
  }

  void clearGraph(){
    _pushHistory();
    _graph.clear();
    notifyListeners();
  }

   bool get canUndo => _history.isNotEmpty;

   void _pushHistory(){
      _history.add(_graph.clone());
      if (_history.length > _maxHistory) {
        _history.removeAt(0);
      }
   }

   void undo(){
     if (_history.isEmpty) return;
     _graph = _history.removeLast();
     notifyListeners();
   }

  Future<List<String>> listSavedGraphs() => _storage.listNames();

  Future<bool> savedGraphExists(String name) => _storage.exists(name);

  Future<void> saveGraph(String name) async {
   await _storage.save(name, _graph.toJson());
  }

  Future<String?> loadGraph(String name) async{
    final json = await _storage.load(name);
    if(json == null) return "Graph not found";
    Graph newGraph = Graph.fromJson(json);
    List<String> messages = rules.validateGraph(newGraph);
    if(messages.isNotEmpty) return messages.first;
    _pushHistory();
    _graph = newGraph;
    notifyListeners();
    return null;
  }

  Future<void> deleteGraph(String name) async {
    await _storage.delete(name);
  }

}
