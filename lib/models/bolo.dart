import 'package:flutter/material.dart';

class BoloPainter extends CustomPainter {
  final Color color;
  BoloPainter({this.color = Colors.white});

  // Lienzo base del bolo
  static const double anchoBase = 100;
  static const double altoBase = 300;

  @override
  void paint(Canvas canvas, Size size) {
    // Escala el lienzo base al tamaño real disponible
    canvas.scale(size.width / anchoBase, size.height / altoBase);

    final cuerpo = Path()
      ..moveTo(50, 0)
      ..cubicTo(70, 0, 72, 40, 60, 62)
      ..cubicTo(52, 78, 52, 90, 62, 115)
      ..cubicTo(100, 170, 95, 250, 82, 290)
      ..lineTo(82, 300)
      ..lineTo(18, 300)
      ..lineTo(18, 290)
      ..cubicTo(5, 250, 0, 170, 38, 115)
      ..cubicTo(48, 90, 48, 78, 40, 62)
      ..cubicTo(28, 40, 30, 0, 50, 0)
      ..close();

    canvas.drawPath(cuerpo, Paint()..color = color);
    canvas.drawPath(
      cuerpo,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawLine(
      const Offset(45, 70),
      const Offset(55, 70),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(covariant BoloPainter old) => old.color != color;
}

class Bolo extends StatelessWidget {
  /// 1.0 = tamaño predeterminado (100 x 300)
  final double escala;
  final Color color;

  const Bolo({super.key, this.escala = 1.0, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(BoloPainter.anchoBase * escala, BoloPainter.altoBase * escala),
      painter: BoloPainter(color: color),
    );
  }
}