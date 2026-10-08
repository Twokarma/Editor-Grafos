import 'package:flutter/material.dart';

class BoloPainter extends CustomPainter {
  final Color color;
  final int? numero;
  BoloPainter({this.color = Colors.white, this.numero});

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


    if (numero != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$numero',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 48, // en unidades del lienzo base
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Centrado horizontal en x = 50, en la parte ancha del cuerpo
      tp.paint(canvas, Offset(50 - tp.width / 2, 200 - tp.height / 2));
    }
  }



  @override
  bool shouldRepaint(covariant BoloPainter old) => old.color != color || old.numero != numero;
}

class Bolo extends StatelessWidget {
  /// 1.0 = tamaño predeterminado (100 x 300)
  final double escala;
  final Color color;
  final int? numero;  

  const Bolo({super.key, this.escala = 1.0, this.color = Colors.white, this.numero});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(BoloPainter.anchoBase * escala, BoloPainter.altoBase * escala),
      painter: BoloPainter(color: color, numero: numero),
    );
  }
}