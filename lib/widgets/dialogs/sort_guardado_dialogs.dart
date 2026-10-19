import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/services/sort_storage_service.dart';

Future<void> guardarValoresDialog({
  required BuildContext context,
  required SortStorageService storage,
  required String algoritmo,
  required List<int> valores,
}) async {
  final ctrl = TextEditingController();

  final nombre = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Guardar valores'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nombre'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final t = ctrl.text.trim();
            Navigator.pop(ctx, t.isEmpty ? null : t);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (nombre == null || !context.mounted) return;

  // Si el nombre ya existe, pide confirmación antes de sobrescribir
  if (await storage.exists(algoritmo, nombre)) {
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ya existe'),
        content: Text('"$nombre" ya está guardado. ¿Sobrescribir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sobrescribir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }

  await storage.save(algoritmo, nombre, valores);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('"$nombre" guardado')),
  );
}

/// Devuelve los valores elegidos, o null si cancela o no hay nada guardado.
Future<List<int>?> cargarValoresDialog({
  required BuildContext context,
  required SortStorageService storage,
  required String algoritmo,
}) async {
  final nombres = await storage.listNames(algoritmo);
  if (!context.mounted) return null;

  if (nombres.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay valores guardados')),
    );
    return null;
  }

  final elegido = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Cargar valores'),
      children: [
        for (final n in nombres)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, n),
            child: Text(n),
          ),
      ],
    ),
  );
  if (elegido == null) return null;

  return storage.load(algoritmo, elegido);
}