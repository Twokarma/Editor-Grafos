import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/rules/assignment_rules.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/rules/johnson_rules.dart';

import '../providers/graph_provider.dart';
import '../screens/assignment_screen.dart';
import '../screens/graph_screen.dart';
import '../screens/insertion_sort.dart';
import '../screens/johnson_screen.dart';
import '../screens/merge_sort.dart';
import '../screens/selection_sort.dart';
import '../screens/shell_sort.dart';

enum AppMode{
  graphMaker('Graph Maker', 'GM', ModeGroup.top, Icons.hub_outlined),
  assignment('Asignación', 'As', ModeGroup.algorithm, Icons.compare_arrows),
  johnson('Johnson', 'Jo', ModeGroup.algorithm, Icons.route),
  selection('Selection', 'Se', ModeGroup.sort, Icons.sort),
  insertion('Insertion', 'In', ModeGroup.sort, Icons.more_horiz),
  merge('Merge', 'Me', ModeGroup.sort, Icons.call_merge),
  shell('Shell', 'Sh', ModeGroup.sort, Icons.more_horiz_rounded);

  const AppMode(this.label, this.initials, this.group, this.icon);

  final String label;
  final String initials;
  final ModeGroup group;
  final IconData icon;

  bool get usesCopy => this == assignment || this == johnson;
  GraphRules get rules => switch(this){
    AppMode.assignment => AssignmentRules(),
    AppMode.johnson => JohnsonRules(),
    AppMode.graphMaker ||
    AppMode.selection ||
    AppMode.insertion ||
    AppMode.merge ||
    AppMode.shell => DefaultRules(),
  };

  Widget buildScreen(GraphProvider main) => switch (this) {
    AppMode.graphMaker => const GraphScreen(),
    AppMode.assignment => AssignmentScreen(mainProvider: main),
    AppMode.johnson => JohnsonScreen(mainProvider: main),
    AppMode.selection => const SelectionSort(),
    AppMode.insertion => const InsertionSort(),
    AppMode.merge => const MergeSort(),
    AppMode.shell => const ShellSort(),
  };
}
enum ModeGroup{top, algorithm, sort}