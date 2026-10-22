/// Problema de transporte: método de la esquina noroeste (solución inicial) y
/// optimización por aproximaciones sucesivas con el método MODI (u-v).
///
/// Se tienen m orígenes con una oferta y n destinos con una demanda. Enviar una
/// unidad del origen i al destino j cuesta costs[i][j] (null = no hay ruta).
/// Se busca el reparto de costo total mínimo (o máximo) que cumpla la oferta y
/// la demanda.
///
/// Pasos:
///  1. Balancear: si la oferta total y la demanda total difieren, se agrega un
///     origen o un destino ficticio (costo 0) que absorbe la diferencia.
///  2. Esquina noroeste: se parte de la celda (0,0) y se asigna lo máximo
///     posible, avanzando hacia abajo o a la derecha. Da una solución factible
///     con m+n-1 celdas básicas (sin mirar los costos).
///  3. MODI, repetido hasta que no se pueda mejorar:
///       a. Potenciales: u[0] = 0 y u[i] + v[j] = c[i][j] en celdas básicas.
///       b. Costo reducido: d[i][j] = c[i][j] - u[i] - v[j] en celdas no básicas.
///       c. Si todos los d >= 0, la solución es óptima. Si no, entra la celda
///          con el d más negativo.
///       d. Ciclo: la celda que entra y el camino único que la une con la base
///          forman un ciclo alternando + y -. Se mueve theta = mínimo de las
///          celdas con signo -, y sale una de ellas.
///
/// Rutas inexistentes: se resuelven con el método de la M grande (costo muy
/// alto). Si al final queda flujo sobre una, el problema no tiene solución.
/// Maximizar equivale a minimizar el costo con signo cambiado.
///
/// Todo en esta clase es Dart puro (sin Flutter), igual que los otros
/// algoritmos de la carpeta.
enum TransportGoal { minimize, maximize }

/// Posición (fila, columna) en la tabla de transporte.
class TransportCell {
  final int row;
  final int col;
  const TransportCell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is TransportCell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// Datos de entrada del problema.
class TransportationProblem {
  /// costs[i][j]: costo unitario del origen i al destino j. null = sin ruta.
  final List<List<double?>> costs;
  final List<double> supply;
  final List<double> demand;
  final TransportGoal goal;

  TransportationProblem({
    required this.costs,
    required this.supply,
    required this.demand,
    this.goal = TransportGoal.minimize,
  }) {
    if (supply.isEmpty || demand.isEmpty) {
      throw ArgumentError('Se necesita al menos un origen y un destino.');
    }
    if (costs.length != supply.length ||
        costs.any((row) => row.length != demand.length)) {
      throw ArgumentError('La matriz de costos no coincide con oferta/demanda.');
    }
    for (final v in [...supply, ...demand]) {
      if (!v.isFinite || v < 0) {
        throw ArgumentError('Oferta y demanda deben ser números no negativos.');
      }
    }
  }
}

/// Solución básica factible: reparto y qué celdas son básicas.
class TransportBasis {
  final List<List<double>> allocation;
  final List<List<bool>> basic;
  const TransportBasis(this.allocation, this.basic);
}

/// Una iteración de MODI (para mostrar el paso a paso).
class TransportationIteration {
  final List<double> u;
  final List<double> v;

  /// Costo reducido por celda; null en las celdas básicas.
  final List<List<double?>> deltas;

  /// Celda que entra a la base.
  final TransportCell entering;

  /// Celdas del ciclo con signo + (la que entra y las alternas) y con signo -.
  final List<TransportCell> plusCells;
  final List<TransportCell> minusCells;

  /// Cantidad que se desplaza por el ciclo.
  final double theta;

  /// Celda que sale de la base.
  final TransportCell leaving;

  /// Reparto, celdas básicas y costo total después de aplicar el ciclo.
  final List<List<double>> allocationAfter;
  final List<List<bool>> basicAfter;
  final double costAfter;

  const TransportationIteration({
    required this.u,
    required this.v,
    required this.deltas,
    required this.entering,
    required this.plusCells,
    required this.minusCells,
    required this.theta,
    required this.leaving,
    required this.allocationAfter,
    required this.basicAfter,
    required this.costAfter,
  });
}

/// Cantidad enviada por una ruta real (no ficticia).
class TransportFlow {
  final int row;
  final int col;
  final double amount;
  const TransportFlow(this.row, this.col, this.amount);
}

class TransportationResult {
  final TransportGoal goal;

  /// Tamaño original (sin filas/columnas ficticias).
  final int realRows;
  final int realCols;

  /// Se agregó un origen (fila) o destino (columna) ficticio para balancear.
  final bool hasDummyRow;
  final bool hasDummyCol;

  /// Datos ya balanceados (incluyen la fila/columna ficticia si la hay).
  final List<List<double?>> costs;
  final List<double> supply;
  final List<double> demand;

  /// Solución inicial por esquina noroeste.
  final List<List<double>> initialAllocation;
  final List<List<bool>> initialBasic;
  final double initialCost;

  /// true si la solución inicial pasa por rutas que no existen.
  final bool initialUsesMissingRoutes;

  final List<TransportationIteration> iterations;

  /// Solución final.
  final List<List<double>> allocation;
  final List<List<bool>> basic;
  final double totalCost;

  /// true si no hay manera de cumplir oferta y demanda con las rutas que existen.
  final bool isInfeasible;

  /// true si se llegó al límite de iteraciones sin terminar (no debería pasar).
  final bool hitIterationLimit;

  const TransportationResult({
    required this.goal,
    required this.realRows,
    required this.realCols,
    required this.hasDummyRow,
    required this.hasDummyCol,
    required this.costs,
    required this.supply,
    required this.demand,
    required this.initialAllocation,
    required this.initialBasic,
    required this.initialCost,
    required this.initialUsesMissingRoutes,
    required this.iterations,
    required this.allocation,
    required this.basic,
    required this.totalCost,
    required this.isInfeasible,
    required this.hitIterationLimit,
  });

  /// Envíos reales de la solución final (sin ficticios ni cantidades 0).
  List<TransportFlow> get realFlows {
    final flows = <TransportFlow>[];
    for (var i = 0; i < realRows; i++) {
      for (var j = 0; j < realCols; j++) {
        if (allocation[i][j] > 1e-9 && costs[i][j] != null) {
          flows.add(TransportFlow(i, j, allocation[i][j]));
        }
      }
    }
    return flows;
  }
}

class _Balanced {
  final List<List<double?>> costs; // con el signo original; null = sin ruta
  final List<List<double>> work; // lo que realmente se minimiza (con M)
  final List<double> supply;
  final List<double> demand;
  final bool dummyRow;
  final bool dummyCol;
  const _Balanced(this.costs, this.work, this.supply, this.demand,
      this.dummyRow, this.dummyCol);
}

class _Potentials {
  final List<double> u;
  final List<double> v;
  const _Potentials(this.u, this.v);
}

class TransportationAlgorithm {
  static const double _eps = 1e-9;
  static const double _feasibilityTolerance = 1e-7;
  static const int maxIterations = 1000;

  /// Resuelve el problema completo: esquina noroeste + MODI.
  static TransportationResult solve(TransportationProblem problem) {
    final b = _balance(problem);
    final m = b.supply.length;
    final n = b.demand.length;

    // ---- Solución inicial ----
    final initial = northwestCorner(b.supply, b.demand);
    final initialCost = _totalCost(b.costs, initial.allocation);
    final initialUsesMissing = _usesMissingRoutes(b.costs, initial.allocation);

    // ---- Optimización (MODI) ----
    final alloc = _copy(initial.allocation);
    final basic = initial.basic.map((r) => List<bool>.from(r)).toList();
    final iterations = <TransportationIteration>[];
    var hitLimit = false;

    while (true) {
      final pot = _potentials(b.work, basic, m, n);

      var best = -_eps;
      TransportCell? entering;
      final deltas = List.generate(m, (_) => List<double?>.filled(n, null));
      for (var i = 0; i < m; i++) {
        for (var j = 0; j < n; j++) {
          if (basic[i][j]) continue;
          final delta = b.work[i][j] - pot.u[i] - pot.v[j];
          deltas[i][j] = delta;
          if (delta < best) {
            best = delta;
            entering = TransportCell(i, j);
          }
        }
      }
      if (entering == null) break; // todos los d >= 0: óptimo

      if (iterations.length >= maxIterations) {
        hitLimit = true;
        break;
      }

      // Ciclo: celda que entra + camino único por la base. El camino sale de
      // la fila de entrada y llega a la columna de entrada; sus celdas
      // alternan - , + , - ... (la primera comparte fila con la que entra).
      final path = _treePath(basic, m, n, entering.row, entering.col);
      if (path.isEmpty) {
        throw StateError('La base no es conexa: no se pudo formar el ciclo.');
      }
      final minus = <TransportCell>[];
      final plus = <TransportCell>[entering];
      for (var k = 0; k < path.length; k++) {
        if (k.isEven) {
          minus.add(path[k]);
        } else {
          plus.add(path[k]);
        }
      }

      var theta = alloc[minus.first.row][minus.first.col];
      for (final c in minus) {
        if (alloc[c.row][c.col] < theta) theta = alloc[c.row][c.col];
      }
      final leaving =
          minus.firstWhere((c) => alloc[c.row][c.col] == theta);

      for (final c in plus) {
        alloc[c.row][c.col] += theta;
      }
      for (final c in minus) {
        alloc[c.row][c.col] -= theta;
      }
      basic[entering.row][entering.col] = true;
      basic[leaving.row][leaving.col] = false;
      alloc[leaving.row][leaving.col] = 0.0;

      iterations.add(TransportationIteration(
        u: pot.u,
        v: pot.v,
        deltas: deltas,
        entering: entering,
        plusCells: plus,
        minusCells: minus,
        theta: theta,
        leaving: leaving,
        allocationAfter: _copy(alloc),
        basicAfter: basic.map((r) => List<bool>.from(r)).toList(),
        costAfter: _totalCost(b.costs, alloc),
      ));
    }

    return TransportationResult(
      goal: problem.goal,
      realRows: problem.supply.length,
      realCols: problem.demand.length,
      hasDummyRow: b.dummyRow,
      hasDummyCol: b.dummyCol,
      costs: b.costs,
      supply: b.supply,
      demand: b.demand,
      initialAllocation: initial.allocation,
      initialBasic: initial.basic,
      initialCost: initialCost,
      initialUsesMissingRoutes: initialUsesMissing,
      iterations: iterations,
      allocation: alloc,
      basic: basic,
      totalCost: _totalCost(b.costs, alloc),
      isInfeasible: _usesMissingRoutes(b.costs, alloc),
      hitIterationLimit: hitLimit,
    );
  }

  /// Método de la esquina noroeste sobre datos ya balanceados
  /// (sum(supply) == sum(demand)). Devuelve siempre m+n-1 celdas básicas.
  ///
  /// Si al asignar se agotan a la vez una oferta y una demanda, solo se
  /// avanza en una dirección; la siguiente celda queda básica con asignación 0
  /// (solución degenerada), que es lo que necesita MODI para tener una base
  /// completa.
  static TransportBasis northwestCorner(
      List<double> supply, List<double> demand) {
    final m = supply.length;
    final n = demand.length;
    final s = List<double>.from(supply);
    final d = List<double>.from(demand);
    final alloc = List.generate(m, (_) => List<double>.filled(n, 0.0));
    final basic = List.generate(m, (_) => List<bool>.filled(n, false));

    var i = 0;
    var j = 0;
    while (true) {
      final x = s[i] < d[j] ? s[i] : d[j];
      alloc[i][j] = x;
      basic[i][j] = true;
      s[i] -= x;
      d[j] -= x;

      if (i == m - 1 && j == n - 1) break;

      final rowDone = s[i] <= _eps;
      final colDone = d[j] <= _eps;
      if (rowDone && colDone) {
        if (i < m - 1) {
          i++;
        } else {
          j++;
        }
      } else if (rowDone) {
        i++;
      } else {
        j++;
      }
    }
    return TransportBasis(alloc, basic);
  }

  // ---------------------------------------------------------------------------

  /// Agrega la fila/columna ficticia si hace falta y arma los costos de trabajo.
  static _Balanced _balance(TransportationProblem p) {
    final supply = List<double>.from(p.supply);
    final demand = List<double>.from(p.demand);
    final costs = p.costs.map((r) => List<double?>.from(r)).toList();

    final sTotal = supply.fold<double>(0, (a, b) => a + b);
    final dTotal = demand.fold<double>(0, (a, b) => a + b);

    var dummyRow = false;
    var dummyCol = false;
    if (sTotal > dTotal + _eps) {
      demand.add(sTotal - dTotal);
      for (final r in costs) {
        r.add(0.0);
      }
      dummyCol = true;
    } else if (dTotal > sTotal + _eps) {
      supply.add(dTotal - sTotal);
      costs.add(List<double?>.filled(demand.length, 0.0));
      dummyRow = true;
    }

    // M grande: mayor que cualquier ahorro posible con rutas reales.
    var maxAbs = 0.0;
    for (final r in costs) {
      for (final c in r) {
        if (c != null && c.abs() > maxAbs) maxAbs = c.abs();
      }
    }
    final total = sTotal > dTotal ? sTotal : dTotal;
    final bigM = (maxAbs + 1) * (total + 1) * 2;
    final sign = p.goal == TransportGoal.maximize ? -1.0 : 1.0;

    final work = [
      for (final r in costs)
        [for (final c in r) c == null ? bigM : sign * c],
    ];
    return _Balanced(costs, work, supply, demand, dummyRow, dummyCol);
  }

  /// Potenciales u (filas) y v (columnas) con u[0] = 0 y u+v = c en la base.
  static _Potentials _potentials(
      List<List<double>> work, List<List<bool>> basic, int m, int n) {
    final u = List<double?>.filled(m, null);
    final v = List<double?>.filled(n, null);
    u[0] = 0.0;

    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < m; i++) {
        for (var j = 0; j < n; j++) {
          if (!basic[i][j]) continue;
          final ui = u[i];
          final vj = v[j];
          if (ui != null && vj == null) {
            v[j] = work[i][j] - ui;
            changed = true;
          } else if (vj != null && ui == null) {
            u[i] = work[i][j] - vj;
            changed = true;
          }
        }
      }
    }
    if (u.contains(null) || v.contains(null)) {
      throw StateError('La base no es conexa: no se pudieron calcular u y v.');
    }
    return _Potentials(
      [for (final x in u) x!],
      [for (final x in v) x!],
    );
  }

  /// Camino entre una fila y una columna usando solo celdas básicas (la base es
  /// un árbol, así que es único). Nodos: filas 0..m-1 y columnas m..m+n-1.
  /// Devuelve las celdas en orden, desde la fila hasta la columna.
  static List<TransportCell> _treePath(
      List<List<bool>> basic, int m, int n, int startRow, int endCol) {
    final target = m + endCol;
    final visited = List<bool>.filled(m + n, false);
    final prevNode = List<int>.filled(m + n, -1);
    final prevCell = List<TransportCell?>.filled(m + n, null);

    visited[startRow] = true;
    final stack = <int>[startRow];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (node == target) break;
      if (node < m) {
        for (var j = 0; j < n; j++) {
          final next = m + j;
          if (basic[node][j] && !visited[next]) {
            visited[next] = true;
            prevNode[next] = node;
            prevCell[next] = TransportCell(node, j);
            stack.add(next);
          }
        }
      } else {
        final j = node - m;
        for (var i = 0; i < m; i++) {
          if (basic[i][j] && !visited[i]) {
            visited[i] = true;
            prevNode[i] = node;
            prevCell[i] = TransportCell(i, j);
            stack.add(i);
          }
        }
      }
    }

    final cells = <TransportCell>[];
    var node = target;
    while (prevCell[node] != null) {
      cells.add(prevCell[node]!);
      node = prevNode[node];
    }
    return cells.reversed.toList();
  }

  static double _totalCost(
      List<List<double?>> costs, List<List<double>> alloc) {
    var total = 0.0;
    for (var i = 0; i < alloc.length; i++) {
      for (var j = 0; j < alloc[i].length; j++) {
        final c = costs[i][j];
        if (c != null && alloc[i][j] > _eps) total += alloc[i][j] * c;
      }
    }
    return total;
  }

  static bool _usesMissingRoutes(
      List<List<double?>> costs, List<List<double>> alloc) {
    for (var i = 0; i < alloc.length; i++) {
      for (var j = 0; j < alloc[i].length; j++) {
        if (costs[i][j] == null && alloc[i][j] > _feasibilityTolerance) {
          return true;
        }
      }
    }
    return false;
  }

  static List<List<double>> _copy(List<List<double>> a) =>
      a.map((r) => List<double>.from(r)).toList();
}
