import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/checkin_trend.dart';

/// 打卡趋势图表
class CheckinTrendChart extends StatelessWidget {
  final List<CheckinTrendPeriod> periods;

  const CheckinTrendChart({super.key, required this.periods});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (periods.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            '暂无趋势数据',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = periods.length <= 16
            ? constraints.maxWidth
            : math.max(constraints.maxWidth, (periods.length * 46).toDouble());

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: 220,
            child: CustomPaint(
              painter: _CheckinTrendChartPainter(
                periods: periods,
                colorScheme: colorScheme,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckinTrendChartPainter extends CustomPainter {
  final List<CheckinTrendPeriod> periods;
  final ColorScheme colorScheme;
  final TextDirection textDirection;

  _CheckinTrendChartPainter({
    required this.periods,
    required this.colorScheme,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    const left = 36.0;
    const top = 18.0;
    const right = 34.0;
    const bottom = 38.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final bottomY = top + chartHeight;
    final maxTotalDays = periods
        .map((period) => period.totalDays)
        .fold<int>(1, math.max);

    for (final value in [0.0, 0.5, 1.0]) {
      final y = bottomY - chartHeight * value;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        '${(value * 100).toStringAsFixed(0)}%',
        Offset(0, y - 8),
        colorScheme.onSurfaceVariant,
        10,
      );
    }

    final step = periods.length == 1 ? 0.0 : chartWidth / (periods.length - 1);
    final barSlot = periods.length == 1 ? chartWidth : step;
    final barWidth = math.max(5.0, math.min(18.0, barSlot * 0.34));
    final linePath = Path();
    final labelEvery = math.max(1, (periods.length / 5).ceil());

    for (var index = 0; index < periods.length; index++) {
      final period = periods[index];
      final x = periods.length == 1
          ? left + chartWidth / 2
          : left + step * index;
      final barHeight = chartHeight * (period.checkedDays / maxTotalDays);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - barWidth / 2,
          bottomY - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(barRect, barPaint);

      final y = bottomY - chartHeight * period.rate;
      if (index == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }

      if (index % labelEvery == 0 || index == periods.length - 1) {
        _drawCenteredText(
          canvas,
          period.label,
          Offset(x, bottomY + 12),
          colorScheme.onSurfaceVariant,
          10,
        );
      }
    }

    canvas.drawPath(linePath, linePaint);

    for (var index = 0; index < periods.length; index++) {
      final period = periods[index];
      final x = periods.length == 1
          ? left + chartWidth / 2
          : left + step * index;
      final y = bottomY - chartHeight * period.rate;
      canvas.drawCircle(Offset(x, y), 4.2, pointPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = colorScheme.surface);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '',
    )..layout(maxWidth: 44);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _CheckinTrendChartPainter oldDelegate) {
    return oldDelegate.periods != periods ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.textDirection != textDirection;
  }
}
