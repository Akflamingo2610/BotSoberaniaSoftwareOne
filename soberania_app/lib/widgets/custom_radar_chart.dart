import 'dart:math' as math;
import 'package:flutter/material.dart';

class CustomRadarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color fillColor;
  final Color borderColor;
  final Color gridColor;
  final Color textColor;

  const CustomRadarChart({
    super.key,
    required this.labels,
    required this.values,
    this.fillColor = const Color(0xFF2196F3),
    this.borderColor = const Color(0xFF1976D2),
    this.gridColor = const Color(0xFFE0E0E0),
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarChartPainter(
          labels: labels,
          values: values,
          fillColor: fillColor,
          borderColor: borderColor,
          gridColor: gridColor,
          textColor: textColor,
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color fillColor;
  final Color borderColor;
  final Color gridColor;
  final Color textColor;

  _RadarChartPainter({
    required this.labels,
    required this.values,
    required this.fillColor,
    required this.borderColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.35;
    final n = labels.length;
    final angleStep = (2 * math.pi) / n;
    final startAngle = -math.pi / 2; // Começa no topo

    // Níveis de escala: 0, 25, 50, 75, 100
    final levels = [0.0, 25.0, 50.0, 75.0, 100.0];
    final levelRadii = levels.map((level) => radius * (level / 100)).toList();

    // 1. Desenhar grades (polígonos concêntricos)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i < levels.length; i++) {
      final levelRadius = levelRadii[i];
      final path = Path();
      for (int j = 0; j < n; j++) {
        final angle = startAngle + angleStep * j;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Eixos
    final axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // 3. Níveis numéricos
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < levels.length; i++) {
      final level = levels[i];

      double tickRadius;
      if (i == 0) {
        tickRadius = 0;
      } else {
        tickRadius = (levelRadii[i - 1] + levelRadii[i]) / 2;
      }

      final angle = startAngle;
      final x = center.dx + tickRadius * math.cos(angle);
      final y = center.dy + tickRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: level.toInt().toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();

      final textOffset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height - 4,
      );

      textPainter.paint(canvas, textOffset);
    }

    // 4. Labels dos eixos
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelDistance = radius + 30;
      final x = center.dx + labelDistance * math.cos(angle);
      final y = center.dy + labelDistance * math.sin(angle);

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.layout();

      final textOffset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    // 5. Polígono de dados
    final dataPath = Path();
    final dataPaint = Paint()
      ..color = fillColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final value = values[i].clamp(0.0, 100.0);
      final valueRadius = radius * (value / 100);
      final angle = startAngle + angleStep * i;
      final x = center.dx + valueRadius * math.cos(angle);
      final y = center.dy + valueRadius * math.sin(angle);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, borderPaint);

    // 6. Pontos nos vértices
    final pointPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < n; i++) {
      final value = values[i].clamp(0.0, 100.0);
      final valueRadius = radius * (value / 100);
      final angle = startAngle + angleStep * i;
      final x = center.dx + valueRadius * math.cos(angle);
      final y = center.dy + valueRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


