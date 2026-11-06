import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'theme.dart';

/// 7-day bar chart; the last bar (today) is drawn in the strong fill.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.values, required this.labels, this.height = 140});
  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(painter: _BarsPainter(values, labels), size: Size.infinite),
      );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.labels);
  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final maxV = values.fold<double>(1, math.max) * 1.08;
    final minV = values.fold<double>(maxV, math.min) * 0.85;
    final grid = Paint()..color = C.border..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = chartH * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final slot = size.width / values.length;
    final w = slot * 0.46;
    for (var i = 0; i < values.length; i++) {
      final h = (values[i] - minV) / (maxV - minV) * chartH;
      final x = slot * i + (slot - w) / 2;
      final last = i == values.length - 1;
      final r = RRect.fromRectAndCorners(Rect.fromLTWH(x, chartH - h, w, h), topLeft: const Radius.circular(6), topRight: const Radius.circular(6));
      canvas.drawRRect(r, Paint()..color = last ? C.fill : C.accent.withValues(alpha: 0.55));
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: T.small.copyWith(color: last ? C.fill : C.ink3, fontWeight: last ? FontWeight.w700 : FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(slot * i + (slot - tp.width) / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values;
}

/// AM / PM grouped bars for the reports screen.
class PairBars extends StatelessWidget {
  const PairBars({super.key, required this.am, required this.pm, required this.labels});
  final List<double> am, pm;
  final List<String> labels;
  @override
  Widget build(BuildContext context) => SizedBox(height: 130, child: CustomPaint(painter: _PairPainter(am, pm, labels), size: Size.infinite));
}

class _PairPainter extends CustomPainter {
  _PairPainter(this.am, this.pm, this.labels);
  final List<double> am, pm;
  final List<String> labels;
  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final maxV = [...am, ...pm].fold<double>(1, math.max) * 1.05;
    final minV = [...am, ...pm].fold<double>(maxV, math.min) * 0.8;
    final slot = size.width / am.length;
    final w = slot * 0.26;
    for (var i = 0; i < am.length; i++) {
      for (final (j, v, color) in [(0, am[i], C.accent), (1, pm[i], C.supportStrong)]) {
        final h = (v - minV) / (maxV - minV) * chartH;
        final x = slot * i + slot / 2 - w - 1 + j * (w + 2);
        canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(x, chartH - h, w, h), topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), Paint()..color = color);
      }
      final tp = TextPainter(text: TextSpan(text: labels[i], style: T.small), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(slot * i + (slot - tp.width) / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_PairPainter old) => true;
}

/// White sparkline for the hero card.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.height = 44});
  final List<double> values;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(height: height, child: CustomPaint(painter: _SparkPainter(values), size: Size.infinite));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max), minV = values.reduce(math.min);
    final span = (maxV - minV).abs() < 1 ? 1 : maxV - minV;
    Offset pt(int i) => Offset(size.width * i / (values.length - 1), size.height - 6 - (values[i] - minV) / span * (size.height - 12));
    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = pt(i - 1), b = pt(i);
      path.cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(path, Paint()..color = Colors.white..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawCircle(pt(values.length - 1), 5, Paint()..color = Colors.white);
    canvas.drawCircle(pt(values.length - 1), 2.5, Paint()..color = C.fill);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}

/// Lactation curve 0-305 days: fitted actual line up to today, dashed projection after it.
class LactationChart extends StatelessWidget {
  const LactationChart({super.key, required this.curve, required this.dim});
  final LactationCurve curve;
  final int dim;
  @override
  Widget build(BuildContext context) => SizedBox(height: 200, child: CustomPaint(painter: _LactPainter(curve, dim), size: Size.infinite));
}

class _LactPainter extends CustomPainter {
  _LactPainter(this.curve, this.dim);
  final LactationCurve curve;
  final int dim;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0, bottom = 20.0;
    final w = size.width - left, h = size.height - bottom;
    const maxY = 50.0;
    Offset pt(int d) => Offset(left + w * d / 305, h - curve.at(d) / maxY * h);
    final grid = Paint()..color = C.border..strokeWidth = 1;
    for (var y = 0; y <= 50; y += 10) {
      final py = h - y / maxY * h;
      canvas.drawLine(Offset(left, py), Offset(size.width, py), grid);
      final tp = TextPainter(text: TextSpan(text: '$y', style: T.small), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, py - tp.height / 2));
    }
    for (final d in [0, 100, 200, 305]) {
      final tp = TextPainter(text: TextSpan(text: '$d', style: T.small), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset((left + w * d / 305 - tp.width / 2).clamp(left, size.width - tp.width), h + 4));
    }
    final actual = Path()..moveTo(pt(1).dx, pt(1).dy);
    for (var d = 2; d <= dim; d++) {
      actual.lineTo(pt(d).dx, pt(d).dy);
    }
    canvas.drawPath(actual, Paint()..color = C.accent..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final dash = Paint()..color = C.supportStrong..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var d = dim; d < 305; d += 8) {
      canvas.drawLine(pt(d), pt(math.min(d + 4, 305)), dash);
    }
    final peak = pt(curve.peakDay);
    canvas.drawCircle(peak, 6, Paint()..color = C.fill);
    canvas.drawCircle(peak, 3, Paint()..color = Colors.white);
    final today = pt(dim);
    canvas.drawLine(Offset(today.dx, 0), Offset(today.dx, h), Paint()..color = C.borderStrong..strokeWidth = 1);
    canvas.drawCircle(today, 5, Paint()..color = C.accent);
    final label = TextPainter(
      text: TextSpan(text: 'Peak day ${curve.peakDay} - ${curve.peakYield.toStringAsFixed(1)} L', style: T.small.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = Rect.fromLTWH((peak.dx - label.width / 2 - 8).clamp(left, size.width - label.width - 16), math.max(0, peak.dy - 34), label.width + 16, label.height + 8);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), Paint()..color = C.ink);
    label.paint(canvas, box.topLeft + const Offset(8, 4));
  }

  @override
  bool shouldRepaint(_LactPainter old) => old.dim != dim || old.curve != curve;
}

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class Donut extends StatelessWidget {
  const Donut({super.key, required this.segments, required this.center, this.size = 132});
  final List<DonutSegment> segments;
  final String center;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(segments),
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(center, style: T.title), Text('Total head', style: T.small)])),
        ),
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments);
  final List<DonutSegment> segments;
  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (t, s) => t + s.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = 2 * math.pi * s.value / total;
      canvas.drawArc(rect, start, math.max(0, sweep - 0.03), false, Paint()..color = s.color..strokeWidth = 18..style = PaintingStyle.stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}
