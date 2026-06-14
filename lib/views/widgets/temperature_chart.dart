import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TemperatureChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const TemperatureChartWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Tidak ada data riwayat suhu")),
      );
    }

    return Container(
      height: 170,
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 15, top: 15, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: CustomPaint(
        painter: TemperatureChartPainter(history),
      ),
    );
  }
}

class TemperatureChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;

  TemperatureChartPainter(this.history);

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Dimensions and paddings
    const double leftPadding = 35.0;
    const double bottomPadding = 20.0;
    const double topPadding = 10.0;
    const double rightPadding = 5.0;

    final double plotWidth = size.width - leftPadding - rightPadding;
    final double plotHeight = size.height - topPadding - bottomPadding;

    // Paint styling
    final paintLine = Paint()
      ..color = const Color(0xFF3B341F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF8ED83F)
      ..style = PaintingStyle.fill;

    final paintDotBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintAxes = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintGrid = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Find min and max values for scaling
    double minTemp = 100.0;
    double maxTemp = 0.0;
    for (var point in history) {
      double temp = (point['suhu'] as num).toDouble();
      if (temp < minTemp) minTemp = temp;
      if (temp > maxTemp) maxTemp = temp;
    }

    // Adjust temperature scale slightly for padding
    if (maxTemp == minTemp) {
      maxTemp += 1.0;
      minTemp -= 1.0;
    } else {
      double diff = maxTemp - minTemp;
      maxTemp += diff * 0.2;
      minTemp -= diff * 0.2;
    }

    // Draw grid lines and Y-axis labels
    const int gridCount = 4;
    for (int i = 0; i < gridCount; i++) {
      double ratio = i / (gridCount - 1);
      double tempVal = minTemp + (maxTemp - minTemp) * ratio;
      double y = topPadding + plotHeight - (ratio * plotHeight);

      // Draw horizontal grid line
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        paintGrid,
      );

      // Draw Y-axis label text
      final textSpan = TextSpan(
        text: "${tempVal.toStringAsFixed(1)}°",
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Calculate plotting points coordinates
    final int count = history.length;
    final double stepX = count > 1 ? plotWidth / (count - 1) : plotWidth;
    final List<Offset> points = [];

    for (int i = 0; i < count; i++) {
      double temp = (history[i]['suhu'] as num).toDouble();
      double x = leftPadding + (i * stepX);
      double y = topPadding + plotHeight - ((temp - minTemp) / (maxTemp - minTemp) * plotHeight);
      points.add(Offset(x, y));

      // Draw X-axis label text (time)
      final timestamp = history[i]['timestamp'] as Timestamp;
      final date = timestamp.toDate();
      final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

      final textSpan = TextSpan(
        text: timeStr,
        style: const TextStyle(
          fontSize: 8,
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 5),
      );
    }

    // Draw gradient fill below line
    final pathFill = Path();
    pathFill.moveTo(points.first.dx, topPadding + plotHeight);
    for (var p in points) {
      pathFill.lineTo(p.dx, p.dy);
    }
    pathFill.lineTo(points.last.dx, topPadding + plotHeight);
    pathFill.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8ED83F).withOpacity(0.4),
          const Color(0xFF8ED83F).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(leftPadding, topPadding, size.width - rightPadding, topPadding + plotHeight));

    canvas.drawPath(pathFill, paintFill);

    // Draw line (smooth bezier)
    final pathLine = Path();
    pathLine.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      pathLine.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p2.dx, p2.dy,
      );
    }
    canvas.drawPath(pathLine, paintLine);

    // Draw axes lines (L-shape)
    // Vertical Y-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + plotHeight),
      paintAxes,
    );
    // Horizontal X-axis
    canvas.drawLine(
      Offset(leftPadding, topPadding + plotHeight),
      Offset(size.width - rightPadding, topPadding + plotHeight),
      paintAxes,
    );

    // Draw dots
    for (var p in points) {
      canvas.drawCircle(p, 5, paintDot);
      canvas.drawCircle(p, 5, paintDotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
