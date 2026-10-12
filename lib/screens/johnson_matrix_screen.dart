import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/models/node.dart';

import '../theme/app_colors.dart';

class JohnsonMatrixScreen extends StatelessWidget{
  final List<Node> nodes;
  final JohnsonResult1 result;
  final headerBk = AppColors.headerBk;

  const JohnsonMatrixScreen({super.key, required this.nodes, required this.result});

  String _fmt(double v) {
    if(v.isInfinite) return "—";
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Widget _cell(String text, {bool header = false, Color? background}) {
    return Container(
      width: 64,
      height: 48,
      alignment: Alignment.center,
      color: background,
      padding: const EdgeInsets.all(4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _table(List<List<double>> matrix){
    List<TableRow> rows = [];

    rows.add(TableRow(children: [
      _cell("", header: true),
      for(final node in nodes) _cell(node.name, header: true),
    ]));

    for (int i = 0; i < nodes.length; i++) {
      rows.add(TableRow(children: [
        _cell(nodes[i].name, header: true),
        for (int j = 0; j < nodes.length; j++) _cell(_fmt(matrix[i][j])),
      ]));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child:
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child:
            Table(
              children: rows,
              border: TableBorder(
                horizontalInside: BorderSide(color: AppColors.matrixBorders, width: 1.0),
              ),
                defaultColumnWidth: FixedColumnWidth(64),
            )
        ),
    );
  }

  @override
  Widget build(BuildContext context){
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Johnson Matrix'),
          bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.trending_up),
                  text: "MAX",
                ),
                Tab(
                  icon: Icon(Icons.trending_down),
                  text: "MIN",
                ),
              ],
          ),
        ),

        body: nodes.isEmpty? const Center(child: Text("No Nodes yet"))
            : TabBarView(
              children: [
                _table(result.distanceMax),
                _table(result.distanceMin),
              ],
        ),
      ),
    );
  }
}