import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/bolo.dart';
import 'package:graph_maker_app_2/models/velocidad.dart';
import 'package:graph_maker_app_2/services/sort_storage_service.dart';
import 'package:graph_maker_app_2/widgets/velocidad_dropdown.dart';
import 'package:graph_maker_app_2/widgets/dialogs/sort_guardado_dialogs.dart';

class ShellSort extends StatefulWidget {
  const ShellSort({super.key});

  @override
  State<StatefulWidget> createState() => _ShellSortState();
}

class _ShellSortState extends State<ShellSort> {
  static const int maxBolos = 20;
  static const int valorMax = 99; // 2 dígitos caben bien dentro del bolo
  static const double escalaInicial = 0.3;
  static const double incremento = 0.08;
  static const String _algoritmo = SortStorageService.grupoCompartido;

  final Random _rand = Random();
  final SortStorageService _storage = SortStorageService();

  double _cantidad = 5;
  late List<int> _valores;

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
  bool _elevado(int idx) => _ordenando && (idx == _actual || idx == _comparado);

  // estado del algoritmo
  bool _ordenando = false;
  int _actual = -1;
  int _comparado = -1;
  int _fijos = 0;

  // temporizador
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
    _actual = _comparado = -1;
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

    for (int gap = n ~/ 2; gap > 0; gap ~/= 2) {
      for (int i = gap; i < n; i++) {
        int k = i;
        setState(() {
          _actual = k;
          _comparado = -1;
        });

        while (k >= gap) {
          setState(() => _comparado = k - gap);
          await Future.delayed(_pausaComparar);
          if (!mounted) return;

          if (_valores[k - gap] > _valores[k]) {
            setState(() {
              final temp = _valores[k - gap];
              _valores[k - gap] = _valores[k];
              _valores[k] = temp;
              _actual = k - gap;
            });
            k -= gap;
            await Future.delayed(_pausaIntercambio);
            if (!mounted) return;
          } else {
            break;
          }
        }
      }
    }

    _cronometro.stop();
    _reloj?.cancel();
    setState(() {
      _ordenando = false;
      _actual = _comparado = -1;
      _fijos = n;
    });
  }

  // ---------- visual ----------

  Color _colorDe(int idx) {
    if (_ordenando) {
      if (idx == _actual) return Colors.orangeAccent;
      if (idx == _comparado) return Colors.yellow;
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
    final min = (ms ~/ 60000).toString().padLeft(2, '0');
    final seg = ((ms ~/ 1000) % 60).toString().padLeft(2, '0');
    final dec = ((ms % 1000) ~/ 100).toString();
    return '$min:$seg.$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Shell Sort (${_valores.length})"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Slider(
            min: 1,
            max: maxBolos.toDouble(),
            divisions: maxBolos - 1,
            label: '${_cantidad.round()}',
            value: _cantidad,
            onChanged: _ordenando ? null : _cambiarCantidad,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
              child: VelocidadDropdown(
                valor: _velocidad,
                onChanged: (v) => setState(() => _velocidad = v),
              ),
            ),

            // Botones (Wrap para que quepan sin desbordar)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _mezclar,
                    icon: const Icon(Icons.shuffle),
                    label: const Text("Mezclar"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _aleatorios,
                    icon: const Icon(Icons.casino),
                    label: const Text("Aleatorio"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _ingresar,
                    icon: const Icon(Icons.edit),
                    label: const Text("Ingresar"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _cargar,
                    icon: const Icon(Icons.folder_open),
                    label: const Text("Cargar"),
                  ),
                  ElevatedButton.icon(
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