import 'package:flutter/material.dart';

class GraphHelp {
  GraphHelp._();

  static Future<void> show(BuildContext context) async {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      await showDialog<void>(
        context: context,
        builder: (_) => const Dialog(
          child: SizedBox(
            width: 520,
            height: 600,
            child: _HelpContent(),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _HelpContent(),
      );
    }
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent();

  static const items = <_HelpItem>[
    _HelpItem(
      Icons.undo,
      'Deshacer',
      'Revierte la última acción realizada en el editor.',
    ),
    _HelpItem(
      Icons.delete_outline,
      'Limpiar grafo',
      'Permite eliminar el contenido del grafo actual.',
    ),
    _HelpItem(
      Icons.save_outlined,
      'Guardar',
      'Guarda el grafo para utilizarlo posteriormente.',
    ),
    _HelpItem(
      Icons.folder_open_outlined,
      'Abrir',
      'Carga un grafo guardado previamente.',
    ),
    _HelpItem(
      Icons.route,
      'Johnson (J)',
      'Ejecuta el algoritmo de Johnson para calcular caminos mínimos entre pares de vértices.',
    ),
    _HelpItem(
      Icons.flag_outlined,
      'Idioma',
      'Permite cambiar el idioma si la función está habilitada.',
    ),
    _HelpItem(
      Icons.grid_view,
      'Matriz M[x]',
      'Abre la vista matricial del grafo.',
    ),
    _HelpItem(
      Icons.more_horiz,
      'Más opciones',
      'Muestra las opciones adicionales disponibles.',
    ),
    _HelpItem(
      Icons.help_outline,
      'Ayuda',
      'Abre esta guía con las funciones principales del editor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ayuda de Graph Maker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Conoce las herramientas disponibles en el editor.',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(item.icon),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(item.description),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem(this.icon, this.title, this.description);
}