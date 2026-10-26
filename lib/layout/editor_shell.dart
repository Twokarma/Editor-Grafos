import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/layout/web_editor_layout.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';

class EditorShell extends StatelessWidget{
    final AppMode mode;
    final String? title;
    final String? hint;
    final Widget canvas;
    final Widget functions;
    final Widget summary;
    final OptionsConfig options;

    const EditorShell ({super.key, required this.mode, this.title, this.hint, required this.canvas, required this.functions, required this.summary, required this.options});

    @override
    Widget build(BuildContext context){
        return LayoutBuilder(builder: (context, constraints){
            final width = constraints.maxWidth;
            final bool menuCollapsed = width < 1200;
            final double columnWidth = width >= 600 && width < 900? 280 : 340;
            return WebEditorLayout(editorShell: this, menuCollapsed: menuCollapsed, columnWidth: columnWidth);
        });
    }
}