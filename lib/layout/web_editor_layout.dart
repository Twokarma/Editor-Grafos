import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';

class WebEditorLayout extends StatefulWidget{
  final EditorShell editorShell;
  final bool menuCollapsed;
  final double columnWidth;

  const WebEditorLayout({super.key, required this.editorShell, required this.menuCollapsed, required this.columnWidth});

  @override
  State<WebEditorLayout> createState() => _WebEditorLayoutState();
}

class _WebEditorLayoutState extends State<WebEditorLayout>{
  late bool _menuCollapsed;
  bool _chatOpen = false;

  bool get toggle => !_menuCollapsed;

  @override
  void initState(){
    super.initState();
    setState(() {
      _menuCollapsed = widget.menuCollapsed;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Padding(
          padding: const EdgeInsetsGeometry.all(Breakpoints.margin),
          child: Row(
            children: [
              SizedBox(
                width: _menuCollapsed? Breakpoints.collapsedMenu : Breakpoints.openedMenu,
                child: Column(),
              ),
              const SizedBox(width: Breakpoints.margin,),
              Expanded(
                child: widget.editorShell.canvas,
              ),
              const SizedBox(width: Breakpoints.margin,),
              SizedBox(
                width: widget.columnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: PanelCard(title: "Funciones", child: widget.editorShell.functions,),
                    ),
                    const SizedBox(height: Breakpoints.margin,),
                    PanelCard(title: "Opciones", child: Text("data"))
                  ],
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}