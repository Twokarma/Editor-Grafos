import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

/// Pone el botón en una caja de [width] px que NO lo obliga a ocupar todo el ancho,
/// así se puede comprobar si se ajusta al texto o se estira.
Widget wrap(Widget child, {double width = 400}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Align(child: child),
          ),
        ),
      ),
    );

Finder _inButton(Finder matching) =>
    find.descendant(of: find.byType(PillButton), matching: matching);

/// La caja con la forma de píldora (la única con ShapeDecoration).
ShapeDecoration decorationOf(WidgetTester t) {
  final box = t.widget<Container>(_inButton(find.byWidgetPredicate(
      (w) => w is Container && w.decoration is ShapeDecoration)));
  return box.decoration! as ShapeDecoration;
}

BorderSide sideOf(WidgetTester t) => (decorationOf(t).shape as StadiumBorder).side;

double opacityOf(WidgetTester t) => t.widget<Opacity>(_inButton(find.byType(Opacity)).first).opacity;

Finder get iconGap => _inButton(find.byWidgetPredicate((w) => w is SizedBox && w.width == 8.0));

void main() {
  group('contenido', () {
    testWidgets('muestra el texto', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'Guardar', style: PillButtonStyle.outline, onTap: () {})));
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('sin ícono: no hay ícono ni hueco de 8 px', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'Guardar', style: PillButtonStyle.outline, onTap: () {})));
      expect(_inButton(find.byType(Icon)), findsNothing);
      expect(iconGap, findsNothing, reason: 'el hueco solo debe existir si hay ícono');
    });

    testWidgets('con ícono: ícono y hueco, del color del texto', (t) async {
      await t.pumpWidget(wrap(PillButton(
          label: 'Deshacer', icon: Icons.undo, style: PillButtonStyle.outline, onTap: () {})));
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(iconGap, findsOneWidget);
      expect(t.widget<Icon>(find.byIcon(Icons.undo)).color, PillButtonStyle.outline.textColor);
    });
  });

  group('toque', () {
    testWidgets('tocar llama a onTap', (t) async {
      var taps = 0;
      await t.pumpWidget(wrap(PillButton(label: 'Abrir', style: PillButtonStyle.outline, onTap: () => taps++)));
      await t.tap(find.byType(PillButton));
      expect(taps, 1);
    });

    testWidgets('tocar el relleno (no el texto) también cuenta', (t) async {
      var taps = 0;
      await t.pumpWidget(wrap(PillButton(label: 'Abrir', style: PillButtonStyle.outline, onTap: () => taps++)));
      final rect = t.getRect(find.byType(PillButton));
      await t.tapAt(Offset(rect.left + 6, rect.center.dy)); // dentro del padding izquierdo
      expect(taps, 1);
    });

    testWidgets('deshabilitado: no hace nada y se ve apagado', (t) async {
      await t.pumpWidget(wrap(const PillButton(label: 'Abrir', style: PillButtonStyle.outline)));
      await t.tap(find.byType(PillButton)); // no debe lanzar
      expect(opacityOf(t), lessThan(1.0));
    });

    testWidgets('habilitado: opacidad completa', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'Abrir', style: PillButtonStyle.outline, onTap: () {})));
      expect(opacityOf(t), 1.0);
    });
  });

  group('estilos', () {
    for (final style in PillButtonStyle.values) {
      testWidgets('${style.name}: fondo y color de texto', (t) async {
        await t.pumpWidget(wrap(PillButton(label: 'X', style: style, onTap: () {})));
        expect(decorationOf(t).color, style.background);
        expect(t.widget<Text>(find.text('X')).style!.color, style.textColor);
      });
    }

    testWidgets('outline: borde del color y grosor del estilo', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'X', style: PillButtonStyle.outline, onTap: () {})));
      final side = sideOf(t);
      expect(side.width, PillButtonStyle.outline.strokeWidth);
      expect(side.color, PillButtonStyle.outline.strokeColor);
    });

    for (final style in [PillButtonStyle.accent, PillButtonStyle.dark]) {
      testWidgets('${style.name}: sin borde (ni siquiera una línea fina)', (t) async {
        await t.pumpWidget(wrap(PillButton(label: 'X', style: style, onTap: () {})));
        expect(sideOf(t).style, BorderStyle.none);
      });
    }

    testWidgets('forma de píldora (extremos redondos)', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'X', style: PillButtonStyle.outline, onTap: () {})));
      expect(decorationOf(t).shape, isA<StadiumBorder>());
    });
  });

  group('tamaño y distribución', () {
    testWidgets('alto mínimo de 48 px', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'X', style: PillButtonStyle.outline, onTap: () {})));
      expect(t.getSize(find.byType(PillButton)).height, greaterThanOrEqualTo(48));
    });

    testWidgets('normal: se ajusta al texto', (t) async {
      await t.pumpWidget(wrap(PillButton(label: 'Abrir', style: PillButtonStyle.outline, onTap: () {})));
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(PillButton)).width, lessThan(400));
    });

    testWidgets('fullWidth: ocupa todo el ancho', (t) async {
      await t.pumpWidget(wrap(PillButton(
          label: 'Abrir', style: PillButtonStyle.outline, fullWidth: true, onTap: () {})));
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(PillButton)).width, 400);
    });

    testWidgets('fullWidth: el texto queda centrado', (t) async {
      await t.pumpWidget(wrap(PillButton(
          label: 'Abrir', style: PillButtonStyle.outline, fullWidth: true, onTap: () {})));
      final button = t.getCenter(find.byType(PillButton)).dx;
      final text = t.getCenter(find.text('Abrir')).dx;
      expect(text, closeTo(button, 1));
    });

    testWidgets('dos botones lado a lado en un Row no dan error', (t) async {
      await t.pumpWidget(wrap(Row(mainAxisSize: MainAxisSize.min, children: [
        PillButton(label: 'Deshacer', icon: Icons.undo, style: PillButtonStyle.outline, onTap: () {}),
        PillButton(label: 'Rehacer', icon: Icons.redo, style: PillButtonStyle.outline, onTap: () {}),
      ])));
      expect(t.takeException(), isNull);
      expect(find.byType(PillButton), findsNWidgets(2));
    });

    testWidgets('texto largo: se corta con … sin desbordar', (t) async {
      await t.pumpWidget(wrap(
        PillButton(
            label: 'Aplicar todos los cambios al grafo principal ahora mismo',
            style: PillButtonStyle.outline,
            fullWidth: true,
            onTap: () {}),
        width: 200,
      ));
      expect(t.takeException(), isNull, reason: 'no debe aparecer el aviso de desborde');
      expect(t.getSize(find.byType(PillButton)).width, lessThanOrEqualTo(200));
    });
  });
}
