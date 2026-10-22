import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/bolo.dart';
import 'package:graph_maker_app_2/models/velocidad.dart';
import 'package:graph_maker_app_2/services/sort_storage_service.dart';
import 'package:graph_maker_app_2/widgets/velocidad_dropdown.dart';
import 'package:graph_maker_app_2/widgets/dialogs/sort_guardado_dialogs.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:graph_maker_app_2/widgets/graph_tour.dart';
import 'package:graph_maker_app_2/screens/pdf_viewer_screen.dart'; // openManual()

class SelectionSort extends StatefulWidget {
  const SelectionSort({super.key});

  @override
  State<SelectionSort> createState() => _SelectionSortState();
}

class _SelectionSortState extends State<SelectionSort> {
  static const int maxBolos = 20;
  static const int valorMax = 99; // 2 dígitos caben bien dentro del bolo
  static const double escalaInicial = 0.3;
  static const double incremento = 0.08;
  static const String _algoritmo = SortStorageService.grupoCompartido;

  final Random _rand = Random();
  final SortStorageService _storage = SortStorageService();

  double _cantidad = 5;
  late List<int> _valores;

  // AYUDA: keys de lo que explica el tour
  final _sliderKey = GlobalKey();
  final _velocidadKey = GlobalKey();
  final _mezclarKey = GlobalKey();
  final _aleatorioKey = GlobalKey();
  final _ingresarKey = GlobalKey();
  final _guardarKey = GlobalKey();
  final _cargarKey = GlobalKey();
  final _resolverKey = GlobalKey();
  final _manualKey = GlobalKey();

  void _startTour() {
    GraphTour.show(context, [
      TourStep(_sliderKey, 'Cantidad de bolos',
          'Elige cuántos bolos quieres ordenar (de 1 a $maxBolos).',
          align: ContentAlign.bottom, shape: ShapeLightFocus.RRect),
      TourStep(_velocidadKey, 'Velocidad',
          'Cambia la velocidad de la animación, incluso mientras ordena.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_mezclarKey, 'Mezclar', 'Desordena los valores actuales.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_aleatorioKey, 'Aleatorio',
          'Genera valores aleatorios, que pueden repetirse.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_ingresarKey, 'Ingresar', 'Escribe tus propios valores a mano.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_guardarKey, 'Guardar',
          'Guarda la secuencia actual para usarla después.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_cargarKey, 'Cargar', 'Abre una secuencia guardada.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_resolverKey, 'Resolver',
          'Ejecuta Selection Sort paso a paso con animación.',
          align: ContentAlign.top, shape: ShapeLightFocus.RRect),
      TourStep(_manualKey, 'Manual', 'Abre el manual en PDF.'),
    ]);
  }

  // velocidad de la animación
  Velocidad _velocidad = Velocidad.normal;

  Duration get _pausaComparar =>
      Duration(milliseconds: (120 * _velocidad.factor).round());
  Duration get _pausaIntercambio =>
      Duration(milliseconds: (350 * _velocidad.factor).round());

  // Duración de la subida/bajada, ligada a la velocidad elegida
  Duration get _duracionAnim => Duration(
      milliseconds: (100 * _velocidad.factor).round().clamp(30, 250).toInt());

  // Los bolos que se están comparando se elevan
  bool _elevado(int idx) => _ordenando && (idx == _j || idx == _min);

  // Estado del algoritmo (para resaltar los bolos)
  bool _ordenando = false;
  int _i = -1; // posición que se está fijando
  int _j = -1; // bolo que se está comparando
  int _min = -1; // menor encontrado hasta ahora
  int _fijos = 0; // cuántos bolos del inicio ya quedaron en su lugar

  // Temporizador
  final Stopwatch _cronometro = Stopwatch();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _generarSecuencial();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  // ---------- generación de valores ----------

  void _generarSecuencial() {
    final n = _cantidad.round();
    _valores = List.generate(n, (i) => i + 1);
    _reiniciarEstado();
  }

  void _reiniciarEstado() {
    _i = _j = _min = -1;
    _fijos = 0;
    _cronometro.reset();
  }

  void _cambiarCantidad(double v) {
    setState(() {
      _cantidad = v;
      _generarSecuencial();
    });
  }

  void _mezclar() {
    setState(() {
      _valores.shuffle();
      _reiniciarEstado();
    });
  }

  // valores aleatorios (pueden repetirse)
  void _aleatorios() {
    setState(() {
      final n = _valores.length;
      _valores = List.generate(n, (_) => _rand.nextInt(valorMax) + 1);
      _reiniciarEstado();
    });
  }

  // ingresar valores a mano
  Future<void> _ingresar() async {
    final ctrl = TextEditingController(text: _valores.join(', '));
    String? error;

    final res = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Ingresar valores'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej: 5, 3, 8, 1',
              helperText:
                  'Separados por coma o espacio (1 a $valorMax, máx. $maxBolos)',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final partes = ctrl.text
                    .split(RegExp(r'[,\s]+'))
                    .where((e) => e.isNotEmpty)
                    .toList();
                final nums = partes.map(int.tryParse).toList();

                if (nums.isEmpty) {
                  setDlg(() => error = 'Ingresa al menos un valor');
                } else if (nums.contains(null)) {
                  setDlg(() => error = 'Solo se permiten números');
                } else if (nums.any((n) => n! < 1 || n > valorMax)) {
                  setDlg(
                      () => error = 'Cada valor debe estar entre 1 y $valorMax');
                } else if (nums.length > maxBolos) {
                  setDlg(() => error = 'Máximo $maxBolos valores');
                } else {
                  Navigator.pop(ctx, nums.cast<int>());
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();

    if (res != null) {
      setState(() {
        _valores = res;
        _cantidad = res.length.toDouble(); // mantiene el slider sincronizado
        _reiniciarEstado();
      });
    }
  }

  // ---------- guardar / cargar ----------

  Future<void> _guardar() => guardarValoresDialog(
        context: context,
        storage: _storage,
        algoritmo: _algoritmo,
        valores: _valores,
      );

  Future<void> _cargar() async {
    final valores = await cargarValoresDialog(
      context: context,
      storage: _storage,
      algoritmo: _algoritmo,
    );
    if (valores == null || !mounted) return;
    setState(() {
      _valores = valores;
      _cantidad = valores.length.toDouble();
      _reiniciarEstado();
    });
  }

  // ---------- algoritmo ----------

  Future<void> _resolver() async {
    setState(() {
      _ordenando = true;
      _fijos = 0;
    });

    _cronometro
      ..reset()
      ..start();
    _reloj = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}),
    );

    final n = _valores.length;

    for (int i = 0; i < n - 1; i++) {
      int indiceMin = i;
      setState(() {
        _i = i;
        _min = indiceMin;
      });

      for (int j = i + 1; j < n; j++) {
        setState(() => _j = j);
        await Future.delayed(_pausaComparar);
        if (!mounted) return;

        if (_valores[j] < _valores[indiceMin]) {
          indiceMin = j;
          setState(() => _min = indiceMin);
        }
      }

      if (indiceMin != i) {
        setState(() {
          final temp = _valores[i];
          _valores[i] = _valores[indiceMin];
          _valores[indiceMin] = temp;
        });
        await Future.delayed(_pausaIntercambio);
        if (!mounted) return;
      }

      setState(() => _fijos = i + 1);
    }

    _cronometro.stop();
    _reloj?.cancel();
    setState(() {
      _ordenando = false;
      _i = _j = _min = -1;
      _fijos = n; // todos en su lugar
    });
  }

  // ---------- visual ----------

  Color _colorDe(int idx) {
    if (_ordenando) {
      if (idx == _min) return Colors.orangeAccent;
      if (idx == _j) return Colors.yellow;
      if (idx == _i) return Colors.lightBlueAccent;
    }
    if (idx < _fijos) return Colors.lightGreenAccent;
    return Colors.white;
  }

  // Tamaño proporcional al valor. Con 1..n queda igual que antes
  // (escalaInicial + i * incremento); con otros valores se reparte
  // el mismo rango de tamaños entre el mínimo y el máximo.
  double _escalaDe(int valor) {
    final minV = _valores.reduce(min);
    final maxV = _valores.reduce(max);
    if (maxV == minV) return escalaInicial + 0.4;
    final rango = (_valores.length - 1) * incremento;
    return escalaInicial + (valor - minV) / (maxV - minV) * rango;
  }

  String get _tiempo {
    final ms = _cronometro.elapsedMilliseconds;
    final minutos = (ms ~/ 60000).toString().padLeft(2, '0');
    final seg = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
    final dec = ((ms % 1000) ~/ 100).toString();
    return '$minutos:$seg.$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Selection Sort (${_valores.length})"),
        actions: [
          IconButton(
            onPressed: _startTour,
            tooltip: "Help",
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            key: _manualKey,
            onPressed: () => openManual(
              context,
              title: 'Selection Sort',
              assetPath: 'assets/docs/Selection_Sort.pdf',
            ),
            tooltip: "Manual",
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Slider(
            key: _sliderKey,
            min: 1,
            max: maxBolos.toDouble(),
            divisions: maxBolos - 1,
            label: '${_cantidad.round()}',
            value: _cantidad,
            // null = slider deshabilitado mientras se ordena
            onChanged: _ordenando ? null : _cambiarCantidad,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Temporizador
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _tiempo,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),

            // Bolos
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int idx = 0; idx < _valores.length; idx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedSlide(
                            offset: Offset(0, _elevado(idx) ? -0.12 : 0),
                            duration: _duracionAnim,
                            curve: Curves.easeOut,
                            child: Bolo(
                              escala: _escalaDe(_valores[idx]),
                              color: _colorDe(idx),
                              numero: _valores[idx],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Velocidad (activa también mientras se ordena)
            Center(
              child: Container(
                key: _velocidadKey,
                child: VelocidadDropdown(
                  valor: _velocidad,
                  onChanged: (v) => setState(() => _velocidad = v),
                ),
              ),
            ),

            // Botones
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    key: _mezclarKey,
                    onPressed: _ordenando ? null : _mezclar,
                    icon: const Icon(Icons.shuffle),
                    label: const Text("Mezclar"),
                  ),
                  ElevatedButton.icon(
                    key: _aleatorioKey,
                    onPressed: _ordenando ? null : _aleatorios,
                    icon: const Icon(Icons.casino),
                    label: const Text("Aleatorio"),
                  ),
                  ElevatedButton.icon(
                    key: _ingresarKey,
                    onPressed: _ordenando ? null : _ingresar,
                    icon: const Icon(Icons.edit),
                    label: const Text("Ingresar"),
                  ),
                  ElevatedButton.icon(
                    key: _guardarKey,
                    onPressed: _ordenando ? null : _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar"),
                  ),
                  ElevatedButton.icon(
                    key: _cargarKey,
                    onPressed: _ordenando ? null : _cargar,
                    icon: const Icon(Icons.folder_open),
                    label: const Text("Cargar"),
                  ),
                  ElevatedButton.icon(
                    key: _resolverKey,
                    onPressed: _ordenando ? null : _resolver,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Resolver"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}