import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/screens/johnson_matrix_screen.dart';
import 'package:graph_maker_app_2/services/johnson_service.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/node.dart';
import '../widgets/dialogs/confirm_exit_copy_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import 'chat_screen.dart';



class JohnsonScreen extends StatefulWidget{
  final GraphProvider mainProvider;
  const JohnsonScreen({super.key, required this.mainProvider});

  @override
  State<JohnsonScreen> createState() => _JohnsonScreenState();
}

class _JohnsonScreenState extends State<JohnsonScreen>{
  JohnsonResult1? _lastResult;
  late String _lastSignature;
  late String _lastAppliedJson;
  JohnsonService? _service;
  Objective _objective = Objective.max;
  String? _from;
  String? _to;
  Set<String> _pathEdgeIds = {};
  String? _message;

  late final GraphProvider _copy;

  @override
  void initState(){
    super.initState();

    _copy = context.read<GraphProvider>();
    _copy.addListener(_onGraphChanged);
    _runJohnson();
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());
  }

  void _onGraphChanged(){
    if(_lastSignature != _structureSignature()) _runJohnson();
  }

  @override
  void dispose(){
    _copy.removeListener(_onGraphChanged);
    super.dispose();
  }

  void _fail(String message){
    setState(() {
      _service = null;
      _lastResult = null;
      _pathEdgeIds = <String>{};
      _from = null;
      _to = null;
      _message = message;
    });
  }

  void _runJohnson(){
    _lastSignature = _structureSignature();
    List<Node> nodes = _copy.graphGetter().nodes.values.toList();
    List<Edge> edges = _copy.graphGetter().edges.values.toList();

    if(edges.isEmpty){
      _fail("There are no edges");
      return;
    }
    List<String> messages = _copy.validateGraph();
    if(messages.isNotEmpty) _fail(messages.first);

    Map<String, int> index = {};
    for(int i = 0; i < nodes.length; i++){
      index[nodes[i].id] = i;
    }

    Set<String> nodesFrom = {};
    Set<String> nodesTo = {};
    for(Edge edge in edges){
      nodesFrom.add(edge.sourceNodeId);
      nodesTo.add(edge.targetNodeId);
    }

    nodesFrom = nodesFrom.difference(nodesTo);
    nodesTo = nodesTo.difference(nodesFrom);

    if(nodesFrom.isEmpty || nodesTo.isEmpty){
      setState(() {
        _message = "No start or end node";
      });
      return;
    }
    String nodeFrom = nodesFrom.difference(nodesTo).first;
    String nodeTo = nodesTo.difference(nodesFrom).first;


    _service =  JohnsonService(nodes: nodes, edges: edges, nodeFrom: nodeFrom, nodeTo: nodeTo);
    JohnsonResult1 result =_service!.run();

    int n = result.distanceMax.length;
    for(int i = 0; i < n; i++){
      if(result.distanceMax[i][i] != 0|| result.distanceMin[i][i] != 0){
        _fail("Cycle detected");
        return;
      }
    }
    setState(() {
      _lastResult = result;
      _objective = Objective.max;
      _from = _service?.nodeFrom;
      _to = _service?.nodeTo;
      _message = null;
    });

    _pathUpdate();
  }

  String _structureSignature(){
    return _copy.graphGetter().nodes.keys.toList().toString() + _copy.graphGetter().edges.values.map((e) => [
      e.id,
      e.sourceNodeId,
      e.targetNodeId,
      e.weight,
      e.directed,
    ]).toList().toString();
  }

  void _pathUpdate(){
    if(_service == null || _lastResult == null || _from == null || _to == null) {
      setState(() {
        _pathEdgeIds = <String>{};
      });
      return;
    }
    Set<String> path = _service!.path(_objective, from: _from, to: _to);
    if(path.isEmpty || _from == _to){
      setState(() {
        _message = "No path from ${_service!.nodes[_service!.index[_from]!].name} to ${_service!.nodes[_service!.index[_to]!].name}";
      });
    }else{
      setState(() {
        _message = null;
      });
    }
    setState(() {
      _pathEdgeIds = path;
    });
  }

  String _buildTextPath(){
    String path = "";
    List<String> copy = _pathEdgeIds.toList();
    Map<String, Node> nodes = _copy.graphGetter().nodes;
    Map<String, Edge> edges = _copy.graphGetter().edges;
    for(int i = copy.length-2; i >= 0; i--){
      path += "${nodes[edges[copy[i]]!.sourceNodeId]!.name} -> ";
    }
    path += "${nodes[edges[copy[0]]!.targetNodeId]!.name} = ${copy[copy.length-1]}";
    return path;
  }

  @override
  Widget build(BuildContext context){
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final bool hasChanges = _lastAppliedJson != currentGraph;
    List<DropdownMenuEntry<String>> dropdownMenuEntries = [];

    void handleMenuSelection(BuildContext context, MenuOption option){
      switch(option){
        case MenuOption.save:
          showSaveDialog(context, graphProviderCopy);
          break;
        case MenuOption.open:
          showOpenDialog(context, graphProviderCopy);
          break;
        case MenuOption.clear:
          graphProviderCopy.clearGraph();
          break;
        case MenuOption.chat:
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: _copy, child: const ChatScreen(),)),
          );
          break;
      }
    }

    void buildDropdownMenuEntries(){
    List<DropdownMenuEntry<String>> entries = [];
      for(Node node in _copy.graphGetter().nodes.values){
        entries.add(
            DropdownMenuEntry<String>(
              value: node.id,
              label: node.name,
            )
        );
      }
      dropdownMenuEntries = entries;
    }
    buildDropdownMenuEntries();

    return PopScope(
        canPop: !hasChanges,
        onPopInvokedWithResult: ((didPop, result) {
          if(didPop) return;
          showConfirmExitCopyDialog(context, widget.mainProvider, _copy);
        }),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Johnson"),
            actions: [
              IconButton(
                icon: const Icon(Icons.publish),
                tooltip: "Apply to main graph",
                onPressed: hasChanges ? () {
                  widget.mainProvider.replaceGraph(_copy.snapshot());
                  setState((){
                    _lastAppliedJson = currentGraph;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Graph Updated'),));
                } : null,
              ),

              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: "Undo",
                onPressed: graphProviderCopy.canUndo ? () => graphProviderCopy.undo() : null,
              ),

              PopupMenuButton<MenuOption>(
                onSelected: (option) => handleMenuSelection(context, option),

                itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.save,
                    child: ListTile(
                      leading: Icon(Icons.save_outlined),
                      title: Text('Save'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.open,
                    child: ListTile(
                      leading: Icon(Icons.folder_open_outlined),
                      title: Text('Open'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.clear,
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Clear'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<MenuOption>(
                    value: MenuOption.chat,
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline),
                      title: Text('ChatAI'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

            ],
          ),
          body: GraphWidget(
              highlightedEdgeIds: _pathEdgeIds,
              holgura: _lastResult != null? _lastResult!.holgura : <String, double>{},
              highlightedColor: _objective == Objective.max? AppColors.maxJohnson : AppColors.minJohnson
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _lastResult != null? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
                  value: _copy,
                  child: JohnsonMatrixScreen(nodes: _service!.nodes, result: _service!.result),)),
              );
            } : null,
            shape: const CircleBorder(),
            child: const Text(
              "M[x]",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),

          bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _pathEdgeIds.isNotEmpty? _buildTextPath() : _message!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: _lastResult == null? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),


                    Row(
                      children: [
                        Expanded(
                          child: DropdownMenu<String>(
                              expandedInsets: EdgeInsets.zero,
                              initialSelection: _from,
                              label: const Text('From'),
                              requestFocusOnTap: false,
                              enabled: _lastResult != null,
                              menuHeight: 300,
                              dropdownMenuEntries: dropdownMenuEntries,
                              onSelected: (String? selection){
                                setState(() {
                                  _from = selection;
                                  _pathUpdate();
                                });
                              },
                          ),
                        ),
                        SizedBox(width: 8.0,),
                        Expanded(
                          child: DropdownMenu<String>(
                            expandedInsets: EdgeInsets.zero,
                            initialSelection: _to,
                            label: const Text('To'),
                            requestFocusOnTap: false,
                            enabled: _lastResult != null,
                            menuHeight: 300,
                            dropdownMenuEntries: dropdownMenuEntries,
                            onSelected: (String? selection){
                              setState(() {
                                _to = selection;
                                _pathUpdate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 17,),

                    Row(
                      children: [
                        Expanded(
                          child:
                            SegmentedButton<Objective>(
                              expandedInsets: EdgeInsets.zero,
                              multiSelectionEnabled: false,
                              emptySelectionAllowed: false,
                              segments: const[
                                ButtonSegment<Objective>(
                                  value: Objective.max,
                                  label: Text('Maximize'),
                                  icon: Icon(Icons.trending_up),
                                ),
                                ButtonSegment<Objective>(
                                  value: Objective.min,
                                  label: Text('Minimize'),
                                  icon: Icon(Icons.trending_down),
                                ),
                              ],
                              selected: <Objective>{_objective},
                              onSelectionChanged: _lastResult != null? (Set<Objective> newObjective){
                                setState(() {
                                  _objective = newObjective.first;
                                });
                                _pathUpdate();
                              } : null,
                            ),
                        ),
                      ],
                    ),
                    if(_message != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            _message!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: _lastResult == null? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        ),
                    ),
                  ],
                ),
              )
          ),
        )
    );
  }
}