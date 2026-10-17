import 'package:flutter/material.dart';

class AppColors {

  //App-wide theme seed (main.dart)
  static const Color themeSeed = Colors.deepPurple;
  //edges
  static const Color leftRightEdge = Color.fromARGB(255, 255, 132, 0);
  static const Color rightLeftEdge = Color.fromARGB(255, 18, 219, 215);
  static const Color selfLoopEdge = Color.fromARGB(255, 102, 18, 219);
  static const Color previewEdge = Color.fromARGB(255, 24, 100, 217);  //nodes
  static const Color lightNodeLabel = Color.fromARGB(255, 255, 255, 255);
  static const Color darkNodeLabel = Color.fromARGB(255, 0, 0, 0);
  static const Color assignmentEdge = Color.fromARGB(255, 0, 189, 0);
  //assignment dummies (view-only overlay)
  static const Color ghostNode = Color.fromARGB(90, 120, 120, 120);
  static const Color ghostNodeBorder = Color.fromARGB(255, 120, 120, 120);
  static const Color ghostEdge = Color.fromARGB(110, 120, 120, 120);
  static const Color noEdgeAssignment = Color.fromARGB(255, 220, 40, 40);
  static const Color maxJohnson = Color.fromARGB(255, 145, 39, 245);
  static const Color minJohnson = Color.fromARGB(255, 255, 200, 0);
  //aiChat
  static const Color userBubbleBackground = Color.fromARGB(255, 0, 168, 240);
  static const Color userBubbleText = Color.fromARGB(255, 255, 255, 255);
  static const Color aiBubbleBackground = Color.fromARGB(255, 196, 241, 255);
  static const Color aiBubbleText = Color.fromARGB(255, 0, 0, 0);
  static const Color placeholderText = Color.fromARGB(255, 0, 168, 240);
  //matrix
  static const Color headerBk = Color.fromARGB(255, 0, 155, 255);
  static const Color summaryBk = Color.fromARGB(255, 138, 204, 255);
  static const Color matrixBorders = Color.fromARGB(127, 0, 66, 117);
  //gridCanvas
  static const Color gridColor = Color.fromARGB(255, 179, 179, 179);
}
