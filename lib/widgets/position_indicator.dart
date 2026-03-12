import 'dart:math' as math;
import 'package:flutter/material.dart';

class PositionIndicator extends StatelessWidget {
  final double angle;

  const PositionIndicator({Key? key, required this.angle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Положение стрелы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(
                painter: _PositionPainter(angle),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${angle.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionPainter extends CustomPainter {
  final double angle;

  _PositionPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw outer circle (semi-transparent)
    final circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, borderPaint);

    // Draw degree markers
    final markerPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 30) {
      final radian = i * math.pi / 180;
      final start = Offset(
        center.dx + (radius - 10) * math.cos(radian),
        center.dy + (radius - 10) * math.sin(radian),
      );
      final end = Offset(
        center.dx + radius * math.cos(radian),
        center.dy + radius * math.sin(radian),
      );
      canvas.drawLine(start, end, markerPaint);
    }

    // Draw needle
    final needleRadian = (angle - 90) * math.pi / 180;
    final needleEnd = Offset(
      center.dx + (radius - 20) * math.cos(needleRadian),
      center.dy + (radius - 20) * math.sin(needleRadian),
    );

    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw center dot
    final centerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}