import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/bolo.dart';

class MergeSort extends StatefulWidget {
  const MergeSort({super.key});

  @override
  State<StatefulWidget> createState() => _MergeSortState();
}

class _MergeSortState extends State<MergeSort> {
  static const int maxBolos = 20;
  static const double escalaInicial = 0.3;
  static const double incremento = 0.08;

  // pausas en la animacion
  static const Duration pausaComparar = Duration(milliseconds: 120);
  static const Duration pausaEscribir = Duration(milliseconds: 300);

  double _cantidad = 5;
  late List<double> _escalas;

  // estado del algoritmo
  bool _ordenando = false;
  int _actual = -1; // posición que se está escribiendo
  int _desde = -1; // inicio del tramo que se está mezclando
  int _hasta = -1; // fin del tramo que se está mezclando
  int _fijos = 0;

  // temporizador
  final Stopwatch _cronometro = Stopwatch();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _generarEscalas();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _generarEscalas() {
    final n = _cantidad.round();
    _escalas = List.generate(n, (i) => escalaInicial + i * incremento);
    _reiniciarEstado();
  }

  void _reiniciarEstado() {
    _actual = _desde = _hasta = -1;
    _fijos = 0;
    _cronometro.reset();
  }

  void _cambiarCantidad(double v) {
    setState(() {
      _cantidad = v;
      _generarEscalas();
    });
  }

  void _mezclar() {
    setState(() {
      _escalas.shuffle();
      _reiniciarEstado();
    });
  }

  Future<void> _resolver() async {
    setState(() {
      _ordenando = true;
      _fijos = 0; // en Merge Sort no hay parte ordenada hasta el final
    });

    _cronometro
      ..reset()
      ..start();
    _reloj = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}),
    );

    await _mergeSort(0, _escalas.length - 1);
    if (!mounted) return;

    _cronometro.stop();
    _reloj?.cancel();
    setState(() {
      _ordenando = false;
      _actual = _desde = _hasta = -1;
      _fijos = _escalas.length; // todos ordenados al terminar
    });
  }

  // Divide el tramo [izq, der] en dos mitades, las ordena y las mezcla
  Future<void> _mergeSort(int izq, int der) async {
    if (!mounted || izq >= der) return;

    final medio = (izq + der) ~/ 2;
    await _mergeSort(izq, medio);
    await _mergeSort(medio + 1, der);
    await _mezclarTramos(izq, medio, der);
  }

  // Mezcla los tramos ordenados [izq, medio] y [medio + 1, der]
  Future<void> _mezclarTramos(int izq, int medio, int der) async {
    if (!mounted) return;

    // Copias de cada mitad
    final izquierda = _escalas.sublist(izq, medio + 1);
    final derecha = _escalas.sublist(medio + 1, der + 1);

    setState(() {
      _desde = izq;
      _hasta = der;
      _actual = -1;
    });

    int i = 0; // índice en izquierda
    int j = 0; // índice en derecha
    int k = izq; // posición donde se escribe

    while (i < izquierda.length && j < derecha.length) {
      setState(() => _actual = k);
      await Future.delayed(pausaComparar);
      if (!mounted) return;

      setState(() {
        if (izquierda[i] <= derecha[j]) {
          _escalas[k] = izquierda[i];
          i++;
        } else {
          _escalas[k] = derecha[j];
          j++;
        }
      });
      k++;
      await Future.delayed(pausaEscribir);
      if (!mounted) return;
    }

    // Lo que sobre de la izquierda
    while (i < izquierda.length) {
      setState(() {
        _actual = k;
        _escalas[k] = izquierda[i];
      });
      i++;
      k++;
      await Future.delayed(pausaEscribir);
      if (!mounted) return;
    }

    // Lo que sobre de la derecha
    while (j < derecha.length) {
      setState(() {
        _actual = k;
        _escalas[k] = derecha[j];
      });
      j++;
      k++;
      await Future.delayed(pausaEscribir);
      if (!mounted) return;
    }

    setState(() {
      _actual = -1;
      _desde = _hasta = -1;
    });
  }

  Color _colorDe(int idx) {
    if (_ordenando) {
      if (idx == _actual) return Colors.orangeAccent;
      if (idx >= _desde && idx <= _hasta) return Colors.yellow;
    }
    if (idx < _fijos) return Colors.lightGreenAccent;
    return Colors.white;
  }

  // Convierte la escala del bolo en su número (1 = el más pequeño)
  int _numeroDe(double escala) =>
      ((escala - escalaInicial) / incremento).round() + 1;

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
        title: Text("Merge Sort (${_escalas.length})"),
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
            // temporizador
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
                      for (int idx = 0; idx < _escalas.length; idx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Bolo(
                            escala: _escalas[idx],
                            color: _colorDe(idx),
                            numero: _numeroDe(_escalas[idx]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Botones
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _ordenando ? null : _mezclar,
                    icon: const Icon(Icons.shuffle),
                    label: const Text("Mezclar"),
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