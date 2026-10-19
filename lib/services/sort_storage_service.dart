import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SortStorageService {
  static const String _prefsKey = "saved_sort_values";

  /// Grupo común: todas las pantallas de sort guardan y cargan aquí.
  static const String grupoCompartido = 'compartido';

  // Estructura guardada:
  // {
  //   "shell":     { "mis valores": [5, 3, 8, 1], "prueba 2": [9, 2] },
  //   "selection": { ... }
  // }

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeAll(Map<String, dynamic> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(all));
  }

  /// Nombres guardados de un algoritmo (ej. "shell").
  Future<List<String>> listNames(String algoritmo) async {
    final all = await _readAll();
    final grupo = (all[algoritmo] as Map<String, dynamic>?) ?? {};
    final names = grupo.keys.toList();
    names.sort();
    return names;
  }

  Future<bool> exists(String algoritmo, String name) async {
    final all = await _readAll();
    final grupo = (all[algoritmo] as Map<String, dynamic>?) ?? {};
    return grupo.containsKey(name);
  }

  Future<void> save(String algoritmo, String name, List<int> valores) async {
    final all = await _readAll();
    final grupo = Map<String, dynamic>.from(
        (all[algoritmo] as Map<String, dynamic>?) ?? {});
    grupo[name] = valores;
    all[algoritmo] = grupo;
    await _writeAll(all);
  }

  Future<List<int>?> load(String algoritmo, String name) async {
    final all = await _readAll();
    final grupo = (all[algoritmo] as Map<String, dynamic>?) ?? {};
    final entry = grupo[name];
    if (entry == null) return null;
    return (entry as List).map((e) => e as int).toList();
  }

  Future<void> delete(String algoritmo, String name) async {
    final all = await _readAll();
    final grupo = Map<String, dynamic>.from(
        (all[algoritmo] as Map<String, dynamic>?) ?? {});
    grupo.remove(name);
    all[algoritmo] = grupo;
    await _writeAll(all);
  }
}