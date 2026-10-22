import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';

void noop() {}

List<OptionKind> kindsOf(OptionsConfig c) => c.visibleOptions().map((o) => o.kind).toList();

OptionItem itemOf(OptionsConfig c, OptionKind kind) =>
    c.visibleOptions().firstWhere((o) => o.kind == kind);

/// Todas las opciones, como en Johnson.
const everything = OptionsConfig(
  onUndo: noop, onRedo: noop, onSave: noop, onOpen: noop, onClear: noop,
  onApply: noop, onManual: noop, onHelp: noop, offersChat: true,
);

void main() {
  group('qué opciones aparecen', () {
    test('sin nada, la lista está vacía', () {
      expect(const OptionsConfig().visibleOptions(), isEmpty);
    });

    test('solo aparecen las opciones que la pantalla ofrece', () {
      expect(kindsOf(const OptionsConfig(onSave: noop, onHelp: noop)), [OptionKind.save, OptionKind.help]);
    });

    test('el chat aparece solo si se ofrece', () {
      expect(kindsOf(const OptionsConfig(onHelp: noop)), isNot(contains(OptionKind.aiChat)));
      expect(kindsOf(const OptionsConfig(onHelp: noop, offersChat: true)), contains(OptionKind.aiChat));
    });

    test('con todo, aparecen las nueve opciones', () {
      expect(everything.visibleOptions(), hasLength(OptionKind.values.length));
    });

    test('ordenamientos: solo manual, ayuda y chat', () {
      const sorts = OptionsConfig(onManual: noop, onHelp: noop, offersChat: true);
      expect(kindsOf(sorts), [OptionKind.manual, OptionKind.help, OptionKind.aiChat]);
    });
  });

  group('orden', () {
    test('sigue el orden del enum', () {
      expect(kindsOf(everything), OptionKind.values);
    });

    test('Deshacer va antes que Rehacer', () {
      final kinds = kindsOf(everything);
      expect(kinds.indexOf(OptionKind.undo), lessThan(kinds.indexOf(OptionKind.redo)));
    });

    test('ChatIA va al final', () {
      expect(kindsOf(everything).last, OptionKind.aiChat);
    });

    test('el orden no depende del orden de los argumentos', () {
      const c = OptionsConfig(onHelp: noop, onSave: noop, onUndo: noop);
      expect(kindsOf(c), [OptionKind.undo, OptionKind.save, OptionKind.help]);
    });
  });

  group('disponible / deshabilitado', () {
    test('por defecto, todo lo ofrecido está habilitado', () {
      for (final item in everything.visibleOptions().where((o) => o.kind != OptionKind.aiChat)) {
        expect(item.action, isNotNull, reason: '${item.kind.label} debería estar habilitado');
      }
    });

    test('sin nada que deshacer: Deshacer aparece pero deshabilitado', () {
      const c = OptionsConfig(onUndo: noop, canUndo: false);
      expect(kindsOf(c), [OptionKind.undo], reason: 'no debe desaparecer');
      expect(itemOf(c, OptionKind.undo).action, isNull);
    });

    test('sin nada que rehacer: Rehacer aparece pero deshabilitado', () {
      const c = OptionsConfig(onRedo: noop, canRedo: false);
      expect(itemOf(c, OptionKind.redo).action, isNull);
    });

    test('sin cambios: Aplicar aparece pero deshabilitado', () {
      const c = OptionsConfig(onApply: noop, hasChanges: false);
      expect(kindsOf(c), [OptionKind.apply]);
      expect(itemOf(c, OptionKind.apply).action, isNull);
    });

    test('los avisos solo afectan a su propia opción', () {
      const c = OptionsConfig(onUndo: noop, onSave: noop, canUndo: false, canRedo: false, hasChanges: false);
      expect(itemOf(c, OptionKind.undo).action, isNull);
      expect(itemOf(c, OptionKind.save).action, isNotNull);
    });

    test('el ítem del chat no lleva acción: la pone el layout', () {
      expect(itemOf(everything, OptionKind.aiChat).action, isNull);
    });
  });

  group('acciones', () {
    test('cada ítem lleva la acción que dio la pantalla', () {
      var saved = 0;
      var opened = 0;
      final c = OptionsConfig(onSave: () => saved++, onOpen: () => opened++);
      itemOf(c, OptionKind.save).action!();
      expect([saved, opened], [1, 0]);
      itemOf(c, OptionKind.open).action!();
      expect([saved, opened], [1, 1]);
    });

    test('actionFor devuelve la acción de cada tipo', () {
      void undo() {}
      final c = OptionsConfig(onUndo: undo);
      expect(c.actionFor(OptionKind.undo), same(undo));
      expect(c.actionFor(OptionKind.save), isNull);
      expect(c.actionFor(OptionKind.aiChat), isNull);
    });
  });

  group('datos del enum', () {
    test('ChatIA usa el estilo oscuro y las demás el de contorno', () {
      for (final kind in OptionKind.values) {
        final expected = kind == OptionKind.aiChat ? 'dark' : 'outline';
        expect(kind.style.name, expected, reason: kind.label);
      }
    });

    test('Deshacer y Rehacer forman el grupo de historial', () {
      final history = OptionKind.values.where((k) => k.group == OptionGroup.history).toList();
      expect(history, [OptionKind.undo, OptionKind.redo]);
    });

    test('ninguna etiqueta está vacía', () {
      for (final kind in OptionKind.values) {
        expect(kind.label.trim(), isNotEmpty);
      }
    });
  });
}
