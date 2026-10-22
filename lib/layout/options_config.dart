import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

enum OptionKind{
  undo('Deshacer', Icons.undo, PillButtonStyle.outline, OptionGroup.history),
  redo('Rehacer', Icons.redo, PillButtonStyle.outline, OptionGroup.history),
  save('Guardar', Icons.save_outlined, PillButtonStyle.outline, OptionGroup.graph),
  open('Abrir', Icons.folder_open_outlined, PillButtonStyle.outline, OptionGroup.graph),
  clear('Limpiar', Icons.delete_sweep_outlined, PillButtonStyle.outline, OptionGroup.graph),
  apply('Aplicar', Icons.publish, PillButtonStyle.outline, OptionGroup.graph),
  manual('Manual', Icons.menu_book_outlined, PillButtonStyle.outline, OptionGroup.graph),
  help('Ayuda', Icons.help_outline, PillButtonStyle.outline, OptionGroup.graph),
  aiChat('ChatIA', Icons.chat_bubble_outline, PillButtonStyle.dark, OptionGroup.graph);

  const OptionKind(this.label, this.icon, this.style, this.group);

  final String label;
  final IconData icon;
  final PillButtonStyle style;
  final OptionGroup group;
}

enum OptionGroup{history, graph}

class OptionsConfig {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;
  final VoidCallback? onOpen;
  final VoidCallback? onClear;
  final VoidCallback? onApply;
  final VoidCallback? onManual;
  final VoidCallback? onHelp;

  final bool canUndo;
  final bool canRedo;
  final bool hasChanges;

  final bool offersChat;

  const OptionsConfig({this.onUndo, this.onRedo, this.onSave, this.onOpen, this.onClear, this.onApply, this.onManual, this.onHelp,
    this.canUndo = true, this.canRedo = true, this.hasChanges = true, this.offersChat = false});

  VoidCallback? actionFor(OptionKind kind) => switch(kind){
    OptionKind.undo => onUndo,
    OptionKind.redo => onRedo,
    OptionKind.save => onSave,
    OptionKind.open => onOpen,
    OptionKind.clear => onClear,
    OptionKind.apply => onApply,
    OptionKind.manual => onManual,
    OptionKind.help => onHelp,
    OptionKind.aiChat => null,
  };

  bool isOffered(OptionKind kind) => kind == OptionKind.aiChat ? offersChat : actionFor(kind) != null;

  bool isAvailable(OptionKind kind) => switch(kind){
    OptionKind.undo => canUndo,
    OptionKind.redo => canRedo,
    OptionKind.apply => hasChanges,
    _ => true,
  };

  List<OptionItem> visibleOptions(){
    List<OptionItem> options = [];
    for(final kind in OptionKind.values){
      if(!isOffered(kind)) continue;
      options.add(OptionItem(kind: kind, action: isAvailable(kind) ? actionFor(kind) : null));
    }
    return options;
  }

}

class OptionItem{
  final OptionKind kind;
  final VoidCallback? action;

  const OptionItem({required this.kind, required this.action});
}
