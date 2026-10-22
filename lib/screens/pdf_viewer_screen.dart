import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfViewer.asset(assetPath),
    );
  }
}

/// Abre el manual único de la app (guía rápida).
/// Abre un PDF de ayuda. Sin parámetros abre la guía rápida general.
void openManual(
  BuildContext context, {
  String title = 'Manual',
  String assetPath = 'assets/docs/graph_maker_guia_rapida.pdf',
}) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => PdfViewerScreen(
      title: title,
      assetPath: assetPath,
    ),
  ));
}