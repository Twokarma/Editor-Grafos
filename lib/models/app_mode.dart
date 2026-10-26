import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/rules/assignment_rules.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/rules/johnson_rules.dart';
import 'package:graph_maker_app_2/rules/transport_rules.dart';
import 'package:graph_maker_app_2/screens/transportation_screen.dart';

import '../providers/graph_provider.dart';
import '../screens/assignment_screen.dart';
import '../screens/graph_screen.dart';
import '../screens/insertion_sort.dart';
import '../screens/johnson_screen.dart';
import '../screens/merge_sort.dart';
import '../screens/selection_sort.dart';
import '../screens/shell_sort.dart';

enum AppMode{
  graphMaker('Graph Maker', 'GM', ModeGroup.top, Icons.hub_outlined, 'Construye y edita grafos: agrega nodos y aristas y observa el resultado'),
  assignment('Asignación', 'As', ModeGroup.algorithm, Icons.compare_arrows, 'Asigna tareas a recursos buscando el menor costo total'),
  johnson('Johnson', 'Jo', ModeGroup.algorithm, Icons.route, 'Calcula caminos mínimos entre todos los pares de vértices'),
  transporte('Transporte', 'Tr', ModeGroup.algorithm, Icons.local_shipping_outlined, 'Reparte unidades desde orígenes hasta destinos al menor costo: esquina noroeste y optimización MODI'),
  selection('Selection', 'Se', ModeGroup.sort, Icons.sort, 'Ordena una lista seleccionando en cada paso el menor elemento restante'),
  insertion('Insertion', 'In', ModeGroup.sort, Icons.more_horiz, 'Ordena insertando cada elemento en su posición dentro de la parte ya ordenada'),
  merge('Merge', 'Me', ModeGroup.sort, Icons.call_merge, 'Ordena comparando elementos separados por un salto que se va reduciendo'),
  shell('Shell', 'Sh', ModeGroup.sort, Icons.more_horiz_rounded, 'Divide la lista en mitades, las ordena y las combina');

  const AppMode(this.label, this.initials, this.group, this.icon, this.description);

  final String label;
  final String initials;
  final ModeGroup group;
  final IconData icon;
  final String description;

  bool get usesCopy => this == assignment || this == johnson || this == transporte;
  GraphRules get rules => switch(this){
    AppMode.assignment => AssignmentRules(),
    AppMode.johnson => JohnsonRules(),
    AppMode.transporte => TransportRules(),
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
    AppMode.transporte => TransportationScreen(mainProvider: main),
    AppMode.selection => const SelectionSort(),
    AppMode.insertion => const InsertionSort(),
    AppMode.merge => const MergeSort(),
    AppMode.shell => const ShellSort(),
  };
}
enum ModeGroup{top, algorithm, sort}