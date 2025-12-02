import 'dart:math';
import 'package:flutter/material.dart';

class PentagonChart extends StatelessWidget {
  final double interior;
  final double satisfaction;
  final double puzzle;
  final double story;
  final double production;
  final double size;
  final Color? fillColor;
  final Color? strokeColor;

  const PentagonChart({
    super.key,
    required this.interior,
    required this.satisfaction,
    required this.puzzle,
    required this.story,
    required this.production,
    this.size = 60,
    this.fillColor,
    this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultFillColor = theme.colorScheme.primary.withValues(alpha: 0.3);
    final defaultStrokeColor = theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PolygonChartPainter(
          values: [interior, satisfaction, puzzle, story, production],
          maxValue: 5.0,
          fillColor: fillColor ?? defaultFillColor,
          strokeColor: strokeColor ?? defaultStrokeColor,
          gridColor: theme.colorScheme.outline.withValues(alpha: 0.3),
          sides: 5,
        ),
      ),
    );
  }
}

// 기존 HexagonChart도 유지 (호환성)
class HexagonChart extends StatelessWidget {
  final double interior;
  final double satisfaction;
  final double puzzle;
  final double story;
  final double production;
  final double horror;
  final double size;
  final Color? fillColor;
  final Color? strokeColor;

  const HexagonChart({
    super.key,
    required this.interior,
    required this.satisfaction,
    required this.puzzle,
    required this.story,
    required this.production,
    required this.horror,
    this.size = 60,
    this.fillColor,
    this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    // HexagonChart를 PentagonChart로 전환 (horror 제외)
    return PentagonChart(
      interior: interior,
      satisfaction: satisfaction,
      puzzle: puzzle,
      story: story,
      production: production,
      size: size,
      fillColor: fillColor,
      strokeColor: strokeColor,
    );
  }
}

class _PolygonChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final int sides;

  _PolygonChartPainter({
    required this.values,
    required this.maxValue,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.sides,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2;

    // 배경 다각형 그리드 그리기
    _drawGrid(canvas, center, radius);

    // 데이터 다각형 그리기
    _drawDataPolygon(canvas, center, radius);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final angleStep = 360 / sides;

    // 외곽 다각형
    final outerPath = _createPolygonPath(center, radius, List.filled(sides, 1.0));
    canvas.drawPath(outerPath, gridPaint);

    // 내부 격자선 (50% 지점)
    final innerPath = _createPolygonPath(center, radius * 0.5, List.filled(sides, 1.0));
    canvas.drawPath(innerPath, gridPaint);

    // 중심에서 각 꼭짓점으로 선
    for (int i = 0; i < sides; i++) {
      final angle = (i * angleStep - 90) * pi / 180;
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, gridPaint);
    }
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double radius) {
    if (values.every((v) => v == 0)) return;

    final normalizedValues = values.map((v) => v / maxValue).toList();
    final path = _createPolygonPath(center, radius, normalizedValues);

    // 채우기
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 테두리
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, strokePaint);

    // 꼭짓점에 점 찍기
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    final angleStep = 360 / sides;
    for (int i = 0; i < sides; i++) {
      final angle = (i * angleStep - 90) * pi / 180;
      final value = normalizedValues[i];
      if (value > 0) {
        final point = Offset(
          center.dx + radius * value * cos(angle),
          center.dy + radius * value * sin(angle),
        );
        canvas.drawCircle(point, 2, dotPaint);
      }
    }
  }

  Path _createPolygonPath(Offset center, double radius, List<double> multipliers) {
    final path = Path();
    final angleStep = 360 / sides;

    for (int i = 0; i < sides; i++) {
      final angle = (i * angleStep - 90) * pi / 180;
      final r = radius * multipliers[i];
      final point = Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PolygonChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.sides != sides;
  }
}
