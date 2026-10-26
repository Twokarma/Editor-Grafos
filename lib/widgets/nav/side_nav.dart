import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';

class SideNav extends StatelessWidget{
  final AppMode mode;
  final bool collapsed;
  final VoidCallbackAction hideShow;
  final VoidCallbackAction? action;
  final VoidCallbackAction back;

  const SideNav({super.key, required this.mode, required this.collapsed, required this.hideShow, this.action, required this.back});


}