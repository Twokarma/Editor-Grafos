import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Contenido de prueba: una barra de color que ocupa el ancho que le den.
Widget bar(String key, {double height = 40}) =>
    SizedBox(key: Key(key), height: height, child: const ColoredBox(color: Colors.blue));

/// Mucho contenido: 30 filas de texto.
Widget tallContent() => Column(children: [for (var i = 0; i < 30; i++) Text('Fila $i')]);

/// Columna derecha del diseño web, tal como debe armarla el layout (paso 4):
/// Funciones con un alto máximo (60 % de la columna) y Opciones con el resto.
/// Ojo: Flexible + Expanded NO sirve, porque Flutter reparte el espacio a partes
/// iguales y Opciones no recibe lo que Funciones deja sin usar.
Widget rightColumn({required Widget funciones, required Widget opciones}) => LayoutBuilder(
      builder: (context, c) => Column(children: [
        ConstrainedBox(constraints: BoxConstraints(maxHeight: c.maxHeight * 0.6), child: funciones),
        const SizedBox(height: 16),
        Expanded(child: opciones),
      ]),
    );

ShapeDecoration decorationOf(WidgetTester t) {
  final box = t.widget<Container>(find.descendant(
    of: find.byType(PanelCard),
    matching: find.byWidgetPredicate((w) => w is Container && w.decoration is ShapeDecoration),
  ));
  return box.decoration! as ShapeDecoration;
}

void main() {
  group('contenido', () {
    testWidgets('muestra el título y el contenido', (t) async {
      await t.pumpWidget(wrap(Center(child: PanelCard(title: 'Funciones', child: bar('hijo')))));
      expect(find.text('Funciones'), findsOneWidget);
      expect(find.byKey(const Key('hijo')), findsOneWidget);
    });

    testWidgets('el título se anuncia como encabezado', (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(wrap(Center(child: PanelCard(title: 'Funciones', child: bar('hijo')))));
      expect(t.getSemantics(find.text('Funciones')), containsSemantics(isHeader: true));
      semantics.dispose();
    });

    testWidgets('un título largo se corta en una línea', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(
          width: 200,
          child: PanelCard(title: 'Un título larguísimo que no cabe', child: bar('hijo')),
        ),
      )));
      expect(t.takeException(), isNull);
      final title = t.widget<Text>(find.text('Un título larguísimo que no cabe'));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });

  group('aspecto', () {
    testWidgets('esquinas redondeadas de 32 px (no biseladas)', (t) async {
      await t.pumpWidget(wrap(Center(child: PanelCard(title: 'Funciones', child: bar('hijo')))));
      final shape = decorationOf(t).shape;
      expect(shape, isA<RoundedRectangleBorder>());
      expect((shape as RoundedRectangleBorder).borderRadius, BorderRadius.circular(32));
    });

    testWidgets('relleno de 24 px: el título empieza 24 px dentro (a la izquierda, no centrado)', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(width: 340, child: PanelCard(title: 'Funciones', child: bar('hijo'))),
      )));
      final card = t.getRect(find.byType(PanelCard));
      final title = t.getRect(find.text('Funciones'));
      expect(title.left - card.left, closeTo(24, 0.5));
      expect(title.top - card.top, closeTo(24, 0.5));
    });

    testWidgets('el contenido se estira a todo el ancho interior', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(width: 340, child: PanelCard(title: 'Funciones', child: bar('hijo'))),
      )));
      expect(t.getSize(find.byKey(const Key('hijo'))).width, closeTo(340 - 48, 0.5));
    });
  });

  group('altura y scroll', () {
    testWidgets('en un Column normal (sin límite de alto) no da error', (t) async {
      await t.pumpWidget(wrap(Column(children: [
        PanelCard(title: 'Funciones', child: bar('hijo')),
      ])));
      expect(t.takeException(), isNull);
    });

    testWidgets('sin límite, se ajusta a su contenido', (t) async {
      await t.pumpWidget(wrap(Column(children: [
        PanelCard(title: 'Funciones', child: bar('hijo', height: 60)),
      ])));
      final card = t.getRect(find.byType(PanelCard));
      final child = t.getRect(find.byKey(const Key('hijo')));
      expect(card.bottom - child.bottom, closeTo(24, 0.5), reason: 'debajo del contenido solo debe quedar el relleno');
    });

    testWidgets('con poco espacio, el contenido hace scroll en vez de desbordar', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(height: 250, child: PanelCard(title: 'Funciones', child: tallContent())),
      )));
      expect(t.takeException(), isNull, reason: 'no deben aparecer las franjas de desborde');
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(t.getSize(find.byType(PanelCard)).height, lessThanOrEqualTo(250));

      expect(find.text('Fila 29').hitTestable(), findsNothing);
      await t.dragUntilVisible(
          find.text('Fila 29'), find.byType(SingleChildScrollView), const Offset(0, -100));
      expect(find.text('Fila 29').hitTestable(), findsOneWidget);
    });

    testWidgets('scrollable: false no añade scroll', (t) async {
      await t.pumpWidget(wrap(Center(
        child: PanelCard(title: 'Funciones', scrollable: false, child: bar('hijo')),
      )));
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('diseño web: Funciones se ajusta y Opciones llena el resto', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(
          key: const Key('columna'),
          height: 560,
          width: 340,
          child: rightColumn(
            funciones: PanelCard(key: const Key('funciones'), title: 'Funciones', child: bar('f', height: 80)),
            opciones: PanelCard(key: const Key('opciones'), title: 'Opciones', child: bar('o')),
          ),
        ),
      )));
      expect(t.takeException(), isNull);

      final column = t.getRect(find.byKey(const Key('columna')));
      final funciones = t.getRect(find.byKey(const Key('funciones')));
      final opciones = t.getRect(find.byKey(const Key('opciones')));

      final fChild = t.getRect(find.byKey(const Key('f')));
      expect(funciones.bottom - fChild.bottom, closeTo(24, 0.5), reason: 'Funciones no debe estirarse');
      expect(opciones.bottom, closeTo(column.bottom, 0.5), reason: 'Opciones llena hasta abajo');
      expect(opciones.top - funciones.bottom, closeTo(16, 0.5));
    });

    testWidgets('diseño web en pantalla corta: Funciones hace scroll', (t) async {
      await t.pumpWidget(wrap(Center(
        child: SizedBox(
          height: 400,
          width: 340,
          child: rightColumn(
            funciones: PanelCard(key: const Key('funciones'), title: 'Funciones', child: tallContent()),
            opciones: PanelCard(title: 'Opciones', child: bar('o')),
          ),
        ),
      )));
      expect(t.takeException(), isNull, reason: 'no deben aparecer las franjas de desborde');
      expect(t.getSize(find.byKey(const Key('funciones'))).height, lessThanOrEqualTo(400 * 0.6 + 0.5),
          reason: 'Funciones no pasa del 60 % y su contenido hace scroll');
    });
  });
}
