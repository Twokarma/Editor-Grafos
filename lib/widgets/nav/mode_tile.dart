import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';

class ModeTile extends StatelessWidget{
  final AppMode mode;
  final bool active;
  final bool collapsed;
  final VoidCallbackAction action;
}