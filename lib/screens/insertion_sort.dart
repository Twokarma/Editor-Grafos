import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/bolo.dart';

class InsertionSort extends StatefulWidget {
  const InsertionSort({super.key});

  @override
  State<InsertionSort> createState() => _InsertionSortState();
}

class _InsertionSortState extends State<InsertionSort> {
  static const int maxBolos = 20;
  static const double escalaInicial = 0.3;
  static const double incremento = 0.08;

  // Pausas de la animación (ajústalas a tu gusto)
  static const Duration pausaComparar = Duration(milliseconds: 120);
  static const Duration pausaIntercambio = Duration(milliseconds: 350);

  double _cantidad = 5;
  late List<double> _escalas;

  // Estado del algoritmo (para resaltar los bolos)
  bool _ordenando = false;
  int _actual = -1;     // bolo que se está insertando
  int _comparado = -1;  // bolo con el que se compara
  int _fijos = 0;       // tamaño de la parte ya ordenada (al inicio)

  // Temporizador
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
    _actual = _comparado = -1;
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
      _fijos = 1; // el primer bolo es, por sí solo, una parte ya ordenada
    });

    _cronometro
      ..reset()
      ..start();
    _reloj = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}),
    );

    final n = _escalas.length;

    for (int i = 1; i < n; i++) {
      int k = i; // posición actual del bolo que estamos insertando
      setState(() {
        _actual = k;
        _comparado = -1;
        _fijos = i;
      });

      // Lo vamos moviendo a la izquierda mientras sea menor que su vecino
      while (k > 0) {
        setState(() => _comparado = k - 1);
        await Future.delayed(pausaComparar);
        if (!mounted) return;

        if (_escalas[k - 1] > _escalas[k]) {
          setState(() {
            final temp = _escalas[k - 1];
            _escalas[k - 1] = _escalas[k];
            _escalas[k] = temp;
            _actual = k - 1;
          });
          k--;
          await Future.delayed(pausaIntercambio);
          if (!mounted) return;
        } else {
          break; // ya está en su lugar dentro de la parte ordenada
        }
      }

      setState(() {
        _comparado = -1;
        _fijos = i + 1;
      });
    }

    _cronometro.stop();
    _reloj?.cancel();
    setState(() {
      _ordenando = false;
      _actual = _comparado = -1;
      _fijos = n; // todos ordenados
    });
  }

  Color _colorDe(int idx) {
    if (_ordenando) {
      if (idx == _actual) return Colors.orangeAccent;
      if (idx == _comparado) return Colors.yellow;
    }
    if (idx < _fijos) return Colors.lightGreenAccent;
    return Colors.white;
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
        title: Text("Insertion Sort (${_escalas.length})"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
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
                      for (int idx = 0; idx < _escalas.length; idx++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Bolo(
                            escala: _escalas[idx],
                            color: _colorDe(idx),
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