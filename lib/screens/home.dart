import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/rules/assignment_rules.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';
import 'package:graph_maker_app_2/rules/johnson_rules.dart';
import 'package:graph_maker_app_2/screens/graph_screen.dart';
import 'package:graph_maker_app_2/screens/assignment_screen.dart';
import 'package:graph_maker_app_2/screens/insertion_sort.dart';
import 'package:graph_maker_app_2/screens/johnson_screen.dart';
import 'package:graph_maker_app_2/screens/merge_sort.dart';
import 'package:graph_maker_app_2/screens/selection_sort.dart';
import 'package:graph_maker_app_2/screens/shell_sort.dart';

/* ==========================================================
   MENÚ PRINCIPAL (equivalente a la página web Graph M4ker)
   - Para agregar un concepto: añade un _Concept a _concepts.
   - Para agregar un método: añade un _Method a _methods.
   ========================================================== */

class _Concept {
  final String title;
  final String text;
  const _Concept(this.title, this.text);
}

class _Method {
  final String name;
  final String description;
  final IconData icon;
  final void Function(BuildContext context) open;
  const _Method(this.name, this.description, this.icon, this.open);
}

const _concepts = <_Concept>[
  _Concept(
    '¿Qué es un grafo?',
    'Un grafo es una estructura que representa relaciones entre objetos. '
        'Los objetos se llaman nodos (o vértices) y las relaciones entre ellos '
        'se llaman aristas.',
  ),
  _Concept(
    '¿Para qué sirven?',
    'Sirven para modelar redes: rutas entre ciudades, conexiones entre '
        'computadoras, relaciones entre personas, dependencias entre tareas. '
        'Permiten responder preguntas como cuál es el camino más corto o cómo '
        'asignar recursos al menor costo.',
  ),
  _Concept(
    'Concepto matemático de un grafo',
    'Formalmente, un grafo es un par G = (V, E), donde V es un conjunto de '
        'vértices y E es un conjunto de aristas, cada una formada por un par '
        'de vértices de V.',
  ),
  _Concept(
    'Tipos de grafos',
    'Dirigidos y no dirigidos, ponderados y no ponderados, simples y '
        'multigrafos, conexos y no conexos, bipartitos, árboles, entre otros.',
  ),
];

/// Abre una pantalla normal (sin copia del grafo).
void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

/// Abre una pantalla que trabaja sobre una COPIA del grafo principal
/// (igual que hacías en GraphScreen con Johnson y Húngaro).
/// `rules` son las reglas de edición del modo (AssignmentRules, JohnsonRules...).
void _pushWithCopy(
  BuildContext context,
  GraphRules rules,
  Widget Function(GraphProvider main) screen,
) {
  final main = context.read<GraphProvider>();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<GraphProvider>(
        create: (_) => GraphProvider(initialGraph: main.snapshot(), graphRules: rules),
        child: screen(main),
      ),
    ),
  );
}

final _methods = <_Method>[
  _Method(
    'Graph Maker',
    'Construye y edita grafos: agrega nodos y aristas y observa el resultado.',
    Icons.hub_outlined,
    (ctx) => _push(ctx, const GraphScreen()),
  ),
  _Method(
    'Assignation Algorithm',
    'Asigna tareas a recursos buscando el menor costo total.',
    Icons.compare_arrows,
    (ctx) => _pushWithCopy(ctx, AssignmentRules(), (main) => AssignmentScreen(mainProvider: main)),
  ),
  _Method(
    'Johnson Algorithm',
    'Calcula caminos mínimos entre todos los pares de vértices.',
    Icons.route,
    (ctx) => _pushWithCopy(ctx, JohnsonRules(), (main) => JohnsonScreen(mainProvider: main)),
  ),
  _Method(
    'Selection Sort',
    'Ordena una lista seleccionando en cada paso el menor elemento restante.',
    Icons.sort,
    (ctx) => _push(ctx, const SelectionSort()),
  ),
  _Method(
    'Insertion Sort',
    'Ordena insertando cada elemento en su posición dentro de la parte ya ordenada.',
    Icons.more_horiz,
    (ctx) => _push(ctx, const InsertionSort()),
  ),
  _Method(
    'Shell Sort',
    'Ordena comparando elementos separados por un salto que se va reduciendo.',
    Icons.more_horiz_rounded,
    (ctx) => _push(ctx, const ShellSort()),
  ),
  _Method(
    'Merge Sort',
    'Divide la lista en mitades, las ordena y las combina.',
    Icons.call_merge,
    (ctx) => _push(ctx, const MergeSort()),
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _openConcept; // acordeón: solo uno abierto a la vez
  int? _openCard; // tarjetas: solo una expandida a la vez

  static const _pageMaxWidth = 1120.0;
  static const _anim = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cs = Theme.of(context).colorScheme;
    final titleSize = (width * 0.11).clamp(48.0, 120.0);
    final sidePad = width > _pageMaxWidth + 48
        ? (width - _pageMaxWidth) / 2
        : 24.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Encabezado ----------
              Padding(
                padding: EdgeInsets.fromLTRB(24, width > 600 ? 72 : 48, 24, 48),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Graph M4ker',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w800,
                          height: 0.95,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'by Windows98',
                        style: TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- Acordeón de conceptos ----------
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePad),
                child: Column(
                  children: [
                    for (var i = 0; i < _concepts.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ConceptTile(
                          concept: _concepts[i],
                          isOpen: _openConcept == i,
                          duration: _anim,
                          onTap: () => setState(
                            () => _openConcept = _openConcept == i ? null : i,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ---------- Algoritmos y ordenamientos ----------
              Padding(
                padding: EdgeInsets.fromLTRB(sidePad, 56, sidePad, 20),
                child: Text(
                  'ALGORITMOS Y ORDENAMIENTOS',
                  style: TextStyle(
                    fontSize: (width * 0.07).clamp(32.0, 76.0),
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _methods.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _MethodCard(
                          method: _methods[i],
                          isOpen: _openCard == i,
                          duration: _anim,
                          onTap: () => setState(
                            () => _openCard = _openCard == i ? null : i,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Concepto (acordeón) ---------- */

class _ConceptTile extends StatelessWidget {
  final _Concept concept;
  final bool isOpen;
  final Duration duration;
  final VoidCallback onTap;

  const _ConceptTile({
    required this.concept,
    required this.isOpen,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : const [],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: isOpen ? 0.375 : 0, // + → ×
                      duration: duration,
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: duration,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? cs.primary : cs.surface,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: isOpen ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        concept.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(74, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        concept.text,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/* ---------- Tarjeta de método ---------- */

class _MethodCard extends StatelessWidget {
  final _Method method;
  final bool isOpen;
  final Duration duration;
  final VoidCallback onTap;

  const _MethodCard({
    required this.method,
    required this.isOpen,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      width: 236,
      transform: Matrix4.translationValues(0, isOpen ? -6 : 0, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      method.icon,
                      size: 56,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                  child: Text(
                    method.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.description,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton(
                            // Navega a la pantalla definida en _methods
                            onPressed: () => method.open(context),
                            child: const Text('Abrir'),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}