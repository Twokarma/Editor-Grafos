import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/bolo.dart';

class ShellSort extends StatefulWidget {
  const ShellSort({super.key});

  @override
  State<StatefulWidget> createState() => _ShellSortState();
}

class _ShellSortState extends State<ShellSort> {
  static const int maxBolos = 20;
  static const double escalaInicial = 0.3;
  static const double incremento = 0.08;

  // pausas en la animacion
  static const Duration pausaComparar = Duration(milliseconds: 120);
  static const Duration pausaIntercambio = Duration(milliseconds: 350);

  double _cantidad = 5;
  late List<double> _escalas;

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
      _fijos = 0; // en Shell Sort no hay parte ordenada hasta el final
    });

    _cronometro
      ..reset()
      ..start();
    _reloj = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() {}),
    );

    final n = _escalas.length;

    // Secuencia de Shell original: n/2, n/4, ..., 1
    for (int gap = n ~/ 2; gap > 0; gap ~/= 2) {
      for (int i = gap; i < n; i++) {
        int k = i; // posición actual del bolo que estamos insertando
        setState(() {
          _actual = k;
          _comparado = -1;
        });

        // Inserción con saltos de tamaño gap
        while (k >= gap) {
          setState(() => _comparado = k - gap);
          await Future.delayed(pausaComparar);
          if (!mounted) return;

          if (_escalas[k - gap] > _escalas[k]) {
            setState(() {
              final temp = _escalas[k - gap];
              _escalas[k - gap] = _escalas[k];
              _escalas[k] = temp;
              _actual = k - gap;
            });
            k -= gap;
            await Future.delayed(pausaIntercambio);
            if (!mounted) return;
          } else {
            break; // ya está en su lugar para este gap
          }
        }
      }
    }

    _cronometro.stop();
    _reloj?.cancel();
    setState(() {
      _ordenando = false;
      _actual = _comparado = -1;
      _fijos = n; // todos ordenados al terminar
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
        title: Text("Shell Sort (${_escalas.length})"),
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