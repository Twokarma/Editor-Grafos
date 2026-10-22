import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/transportation.dart';

// Los costos óptimos esperados se calcularon aparte con un solver exacto de
// programación lineal, no con este mismo código.

TransportationResult solve(
  List<List<double?>> costs,
  List<double> supply,
  List<double> demand, {
  TransportGoal goal = TransportGoal.minimize,
}) {
  return TransportationAlgorithm.solve(TransportationProblem(
    costs: costs,
    supply: supply,
    demand: demand,
    goal: goal,
  ));
}

/// La solución final cumple exactamente oferta y demanda (con la ficticia).
void expectBalanced(TransportationResult r) {
  for (var i = 0; i < r.supply.length; i++) {
    final sent = r.allocation[i].fold<double>(0, (a, b) => a + b);
    expect(sent, closeTo(r.supply[i], 1e-9), reason: 'oferta de la fila $i');
  }
  for (var j = 0; j < r.demand.length; j++) {
    var received = 0.0;
    for (var i = 0; i < r.supply.length; i++) {
      received += r.allocation[i][j];
    }
    expect(received, closeTo(r.demand[j], 1e-9), reason: 'demanda de la columna $j');
  }
}

int countBasic(List<List<bool>> basic) =>
    basic.fold<int>(0, (a, row) => a + row.where((b) => b).length);

void main() {
  const classicCosts = <List<double?>>[
    [19.0, 30.0, 50.0, 10.0],
    [70.0, 30.0, 40.0, 60.0],
    [40.0, 8.0, 70.0, 20.0],
  ];
  const classicSupply = [7.0, 9.0, 18.0];
  const classicDemand = [5.0, 8.0, 7.0, 14.0];

  group('Esquina noroeste', () {
    test('asigna desde la esquina superior izquierda', () {
      final basis =
          TransportationAlgorithm.northwestCorner(classicSupply, classicDemand);
      expect(basis.allocation, [
        [5.0, 2.0, 0.0, 0.0],
        [0.0, 6.0, 3.0, 0.0],
        [0.0, 0.0, 4.0, 14.0],
      ]);
      expect(countBasic(basis.basic), 3 + 4 - 1);
    });

    test('caso degenerado: mantiene m+n-1 celdas básicas (con ceros)', () {
      final basis = TransportationAlgorithm.northwestCorner(
          [10.0, 10.0, 10.0], [10.0, 10.0, 10.0]);
      expect(basis.allocation, [
        [10.0, 0.0, 0.0],
        [0.0, 10.0, 0.0],
        [0.0, 0.0, 10.0],
      ]);
      expect(countBasic(basis.basic), 3 + 3 - 1);
    });
  });

  group('Optimización (MODI)', () {
    test('problema balanceado', () {
      final r = solve(classicCosts, classicSupply, classicDemand);
      expect(r.hasDummyRow, isFalse);
      expect(r.hasDummyCol, isFalse);
      expect(r.initialCost, 1015);
      expect(r.totalCost, 743);
      expect(r.isInfeasible, isFalse);
      expect(r.hitIterationLimit, isFalse);
      expectBalanced(r);
    });

    test('cada iteración no empeora el costo y la última coincide con el final', () {
      final r = solve(classicCosts, classicSupply, classicDemand);
      expect(r.iterations, isNotEmpty);
      var previous = r.initialCost;
      for (final it in r.iterations) {
        expect(it.costAfter, lessThanOrEqualTo(previous + 1e-9));
        previous = it.costAfter;
      }
      expect(r.iterations.last.costAfter, closeTo(r.totalCost, 1e-9));
      expect(countBasic(r.basic), 3 + 4 - 1);
    });

    test('oferta mayor que la demanda: destino ficticio', () {
      final r = solve(
        const [
          [4.0, 6.0, 8.0],
          [5.0, 3.0, 7.0],
        ],
        [40.0, 30.0],
        [20.0, 25.0, 15.0],
      );
      expect(r.hasDummyCol, isTrue);
      expect(r.hasDummyRow, isFalse);
      expect(r.initialCost, 320);
      expect(r.totalCost, 270);
      expectBalanced(r);
    });

    test('demanda mayor que la oferta: origen ficticio', () {
      final r = solve(
        const [
          [4.0, 6.0, 8.0],
          [5.0, 3.0, 7.0],
        ],
        [20.0, 30.0],
        [20.0, 25.0, 15.0],
      );
      expect(r.hasDummyRow, isTrue);
      expect(r.hasDummyCol, isFalse);
      expect(r.iterations, isEmpty); // la esquina noroeste ya era óptima
      expect(r.totalCost, 190);
      expectBalanced(r);
    });

    test('solución inicial degenerada', () {
      final r = solve(
        const [
          [8.0, 6.0, 10.0],
          [9.0, 12.0, 13.0],
          [14.0, 9.0, 16.0],
        ],
        [10.0, 10.0, 10.0],
        [10.0, 10.0, 10.0],
      );
      expect(r.initialCost, 360);
      expect(r.totalCost, 280);
      expect(r.hitIterationLimit, isFalse);
      expectBalanced(r);
      expect(countBasic(r.basic), 3 + 3 - 1);
    });

    test('ruta inexistente: se evita aunque la esquina noroeste la use', () {
      final r = solve(
        const [
          [4.0, null, 8.0],
          [5.0, 3.0, 7.0],
          [6.0, 9.0, 2.0],
        ],
        [20.0, 25.0, 15.0],
        [15.0, 20.0, 25.0],
      );
      expect(r.initialUsesMissingRoutes, isTrue);
      expect(r.isInfeasible, isFalse);
      expect(r.totalCost, 225);
      expect(r.realFlows.any((f) => f.row == 0 && f.col == 1), isFalse);
      expectBalanced(r);
    });

    test('sin solución cuando faltan rutas', () {
      final r = solve(
        const [
          [4.0, null],
          [5.0, null],
        ],
        [10.0, 10.0],
        [10.0, 10.0],
      );
      expect(r.isInfeasible, isTrue);
    });

    test('maximizar', () {
      final r = solve(classicCosts, classicSupply, classicDemand,
          goal: TransportGoal.maximize);
      expect(r.totalCost, 1548);
      expectBalanced(r);
    });

    test('costos negativos al minimizar', () {
      // Con costos negativos no cambia nada: MODI sirve igual.
      final r = solve(
        const [
          [-2.0, 3.0],
          [4.0, -1.0],
        ],
        [5.0, 5.0],
        [5.0, 5.0],
      );
      expect(r.totalCost, -15);
      expectBalanced(r);
    });
  });

  group('Validación', () {
    test('rechaza oferta negativa', () {
      expect(
        () => TransportationProblem(
          costs: const [
            [1.0]
          ],
          supply: const [-1.0],
          demand: const [1.0],
        ),
        throwsArgumentError,
      );
    });

    test('rechaza matriz con tamaño distinto', () {
      expect(
        () => TransportationProblem(
          costs: const [
            [1.0, 2.0]
          ],
          supply: const [1.0],
          demand: const [1.0],
        ),
        throwsArgumentError,
      );
    });
  });
}
