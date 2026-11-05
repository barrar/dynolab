import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dyno_data.dart';
import 'value_format.dart';

const ink = Color(0xFF202624);
const muted = Color(0xFF7B837F);
const lineColor = Color(0xFFE8EBE7);

enum Metric { both, power, torque }

class ChartRun {
  ChartRun(
    this.config,
    this.color,
    this.letter, {
    double? weightLb,
    this.loadWeightLb = 0,
    this.weightLabel = '',
  }) : weightLb = weightLb ?? config.bike.referenceWeightLb;
  final Configuration config;
  final Color color;
  final String letter;
  final double weightLb, loadWeightLb;
  final String weightLabel;
  double get totalWeightLb =>
      combinedWeight(weightLb, gearLb: loadWeightLb, includeLoad: true);
  double get peakHpPer100Lb =>
      horsepowerPer100Pounds(config.peakHp, totalWeightLb);
  double get peakHpPerLb => horsepowerPerPound(config.peakHp, totalWeightLb);
  double? hpPerLbAt(double rpm) {
    final point = config.at(rpm);
    return point == null ? null : horsepowerPerPound(point.hp, totalWeightLb);
  }
}

// Separate common axes preserve physical units for all visible runs.
double roundedAxisMax(Iterable<double> values, {double fallback = .1}) {
  final peak = values.fold(0.0, (value, n) => math.max(value, n));
  if (peak <= 0) return fallback;
  final rawStep = peak / 5;
  final magnitude = math
      .pow(10, (math.log(rawStep) / math.ln10).floor())
      .toDouble();
  final factor = rawStep / magnitude;
  final step = [1.0, 2.0, 2.5, 5.0, 10.0].firstWhere((n) => n >= factor);
  return step * magnitude * 5;
}

double powerToWeightAxisMax(List<ChartRun> runs) =>
    roundedAxisMax(runs.map((r) => r.peakHpPer100Lb));
double torqueToWeightAxisMax(List<ChartRun> runs) => roundedAxisMax(
  runs.map((r) => torquePer100Pounds(r.config.peakNm, r.totalWeightLb)),
);

class DynoChart extends StatelessWidget {
  const DynoChart({
    super.key,
    required this.runs,
    required this.rpm,
    required this.onRpm,
    required this.metric,
    this.normalizeByWeight = false,
  });
  final List<ChartRun> runs;
  final double rpm;
  final ValueChanged<double> onRpm;
  final Metric metric;
  final bool normalizeByWeight;
  static const minRpm = 2500.0, maxRpm = 10500.0;
  static double minFor(List<ChartRun> runs) => runs.fold(
    minRpm,
    (v, r) => r.config.hasCurve
        ? math.min(v, (r.config.minRpm / 500).floor() * 500.0)
        : v,
  );
  static double maxFor(List<ChartRun> runs) => runs.fold(
    maxRpm,
    (v, r) => r.config.hasCurve && r.config.maxRpm > v
        ? (r.config.maxRpm / 1000).ceil() * 1000.0
        : v,
  );
  static Rect plot(Size size, {bool normalized = false}) => Rect.fromLTRB(
    normalized
        ? 54
        : size.width < 500
        ? 37
        : 49,
    35,
    size.width -
        (normalized
            ? 56
            : size.width < 500
            ? 39
            : 52),
    size.height - 45,
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final area = plot(size, normalized: normalizeByWeight);
      final low = minFor(runs), high = maxFor(runs);
      void update(Offset offset) {
        final fraction = ((offset.dx - area.left) / area.width).clamp(0.0, 1.0);
        onRpm((low + fraction * (high - low)).roundToDouble());
      }

      return Semantics(
        label:
            'Interactive dyno graph. RPM ${formatRpm(rpm)}. Use left and right arrow keys to move the cursor.',
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight) {
                onRpm(
                  (rpm +
                          (event.logicalKey == LogicalKeyboardKey.arrowRight
                              ? 100
                              : -100))
                      .clamp(low, high),
                );
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            onHover: (event) => update(event.localPosition),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (event) => update(event.localPosition),
              onHorizontalDragStart: (event) => update(event.localPosition),
              onHorizontalDragUpdate: (event) => update(event.localPosition),
              child: CustomPaint(
                size: size,
                painter: _DynoPainter(runs, rpm, metric, normalizeByWeight),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Marker {
  _Marker(this.position, this.label, this.color, this.torque);
  final Offset position;
  final String label;
  final Color color;
  final bool torque;
  double labelY = 0;
}

class _DynoPainter extends CustomPainter {
  _DynoPainter(this.runs, this.rpm, this.metric, this.normalizeByWeight);
  final List<ChartRun> runs;
  final double rpm;
  final Metric metric;
  final bool normalizeByWeight;
  final markers = <_Marker>[];
  void label(
    Canvas canvas,
    String text,
    Offset at, {
    double fontSize = 10,
    Color color = muted,
    FontWeight weight = FontWeight.w500,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: fontSize,
          color: color,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        at.dx -
            (align == TextAlign.center
                ? painter.width / 2
                : align == TextAlign.right
                ? painter.width
                : 0),
        at.dy,
      ),
    );
  }

  void dashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 5,
    double gap = 5,
  }) {
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += dash + gap) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    markers.clear();
    final area = DynoChart.plot(size, normalized: normalizeByWeight);
    final compact = size.width < 500;
    final normalized = normalizeByWeight;
    final powerMax = normalized
        ? powerToWeightAxisMax(runs)
        : roundedAxisMax([50, ...runs.map((r) => r.config.peakHp)]);
    final torqueMax = normalized
        ? torqueToWeightAxisMax(runs)
        : roundedAxisMax([40, ...runs.map((r) => torqueLbFt(r.config.peakNm))]);
    final powerUnit = normalized ? 'hp/100 lb' : 'hp';
    final torqueUnit = normalized ? 'lb-ft/100 lb' : 'lb-ft';
    final low = DynoChart.minFor(runs), high = DynoChart.maxFor(runs);
    double x(double r) => area.left + (r - low) / (high - low) * area.width;
    double y(double value, bool torque) =>
        area.bottom - value / (torque ? torqueMax : powerMax) * area.height;
    String tick(double max, int i) => formatValue(max * i / 5);
    double plottedHp(double hp, ChartRun run) =>
        normalized ? horsepowerPer100Pounds(hp, run.totalWeightLb) : hp;
    final grid = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    label(
      canvas,
      normalized
          ? (compact ? 'POWER\nhp/100 lb' : 'POWER / hp/100 lb')
          : compact
          ? 'POWER / hp'
          : 'HORSEPOWER / hp',
      Offset(area.left, 2),
      fontSize: 9,
      weight: FontWeight.w700,
    );
    label(
      canvas,
      compact && normalized ? 'TORQUE\n$torqueUnit' : 'TORQUE / $torqueUnit',
      Offset(area.right, 2),
      fontSize: 9,
      weight: FontWeight.w700,
      align: TextAlign.right,
    );
    for (var i = 0; i <= 5; i++) {
      final yy = area.bottom - i / 5 * area.height;
      canvas.drawLine(Offset(area.left, yy), Offset(area.right, yy), grid);
      if (metric != Metric.torque) {
        label(
          canvas,
          tick(powerMax, i),
          Offset(area.left - 12, yy - 7),
          align: TextAlign.right,
        );
      }
      if (metric != Metric.power) {
        label(canvas, tick(torqueMax, i), Offset(area.right + 12, yy - 7));
      }
    }
    for (
      var r = (low / 1000).ceil() * 1000;
      r <= high;
      r += compact
          ? (high - low > 11000 ? 3000 : 2000)
          : (high - low > 15000 ? 2000 : 1000)
    ) {
      canvas.drawLine(
        Offset(x(r.toDouble()), area.top),
        Offset(x(r.toDouble()), area.bottom),
        grid,
      );
      label(
        canvas,
        formatRpm(r),
        Offset(x(r.toDouble()), area.bottom + 14),
        align: TextAlign.center,
      );
    }
    label(
      canvas,
      'ENGINE SPEED / RPM',
      Offset(area.center.dx, size.height - 10),
      fontSize: 8,
      weight: FontWeight.w700,
      align: TextAlign.center,
    );
    canvas.save();
    canvas.clipRect(area.inflate(2));
    for (final run in runs) {
      if (!run.config.hasCurve) continue;
      for (final torque in [true, false]) {
        if ((torque && metric == Metric.power) ||
            (!torque && metric == Metric.torque)) {
          continue;
        }
        final path = Path();
        final points = run.config.points;
        for (var i = 0; i < points.length; i++) {
          final p = points[i];
          final px = x(p.rpm),
              py = y(
                torque
                    ? (normalized
                          ? torquePer100Pounds(p.torqueNm, run.totalWeightLb)
                          : torqueLbFt(p.torqueNm))
                    : normalized
                    ? horsepowerPer100Pounds(p.hp, run.totalWeightLb)
                    : p.hp,
                torque,
              );
          if (i == 0) {
            path.moveTo(px, py);
          } else if (torque) {
            path.lineTo(px, py);
          } else {
            final previous = points[i - 1];
            final rpmDelta = p.rpm - previous.rpm;
            final torqueDelta = p.torqueNm - previous.torqueNm;
            final controlHp =
                previous.hp +
                (previous.torqueNm * rpmDelta + previous.rpm * torqueDelta) /
                    (2 * hpRpmPerNm);
            path.quadraticBezierTo(
              x((previous.rpm + p.rpm) / 2),
              y(plottedHp(controlHp, run), false),
              px,
              py,
            );
          }
        }
        if (!torque) {
          final fill = Path.from(path)
            ..lineTo(x(points.last.rpm), area.bottom)
            ..lineTo(x(points.first.rpm), area.bottom)
            ..close();
          canvas.drawPath(
            fill,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  run.color.withValues(alpha: .065),
                  run.color.withValues(alpha: 0),
                ],
              ).createShader(area),
          );
        }
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = torque ? 2 : 2.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = run.color.withValues(alpha: torque ? .65 : 1);
        if (torque) {
          dashed(canvas, path, paint, dash: 5, gap: 5);
        } else {
          canvas.drawPath(path, paint);
        }
        final p = run.config.at(rpm);
        if (p != null) {
          final value = torque
              ? (normalized
                    ? torquePer100Pounds(p.torqueNm, run.totalWeightLb)
                    : torqueLbFt(p.torqueNm))
              : normalized
              ? horsepowerPer100Pounds(p.hp, run.totalWeightLb)
              : p.hp;
          markers.add(
            _Marker(
              Offset(x(rpm), y(value, torque)),
              '${run.letter}  ${formatValue(value)} ${torque ? torqueUnit : powerUnit}',
              run.color,
              torque,
            ),
          );
        }
      }
    }
    canvas.restore();
    final cursorX = x(rpm);
    final cursorPaint = Paint()
      ..color = const Color(0xFF9EA8A1)
      ..strokeWidth = 1;
    dashed(
      canvas,
      Path()
        ..moveTo(cursorX, area.top)
        ..lineTo(cursorX, area.bottom),
      cursorPaint,
      dash: 3,
      gap: 4,
    );
    final rpmBadge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          cursorX.clamp(area.left + 37, area.right - 37),
          area.bottom + 21,
        ),
        width: 74,
        height: 24,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(rpmBadge, Paint()..color = ink);
    label(
      canvas,
      '${formatRpm(rpm)} rpm',
      Offset(rpmBadge.center.dx, rpmBadge.top + 5),
      color: Colors.white,
      fontSize: 9,
      weight: FontWeight.w700,
      align: TextAlign.center,
    );
    markers.sort((a, b) => a.position.dy.compareTo(b.position.dy));
    final labelHeight = compact ? 21.0 : 24.0;
    for (var i = 0; i < markers.length; i++) {
      markers[i].labelY = math.max(
        area.top + labelHeight / 2,
        math.max(
          markers[i].position.dy,
          i == 0 ? area.top : markers[i - 1].labelY + labelHeight + 3,
        ),
      );
    }
    if (markers.isNotEmpty &&
        markers.last.labelY > area.bottom - labelHeight / 2) {
      markers.last.labelY = area.bottom - labelHeight / 2;
      for (var i = markers.length - 2; i >= 0; i--) {
        markers[i].labelY = math.min(
          markers[i].labelY,
          markers[i + 1].labelY - labelHeight - 3,
        );
      }
    }
    for (final marker in markers) {
      final width = normalized
          ? (compact ? 132.0 : 148.0)
          : (compact ? 91.0 : 104.0);
      final right = cursorX < area.center.dx;
      final left = (right ? cursorX + 14 : cursorX - width - 14).clamp(
        area.left + 1,
        area.right - width - 1,
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          marker.labelY - labelHeight / 2,
          width,
          labelHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawLine(
        marker.position,
        Offset(right ? rect.left : rect.right, rect.center.dy),
        Paint()
          ..color = marker.color.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 1)),
        Paint()..color = ink.withValues(alpha: .06),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = marker.color.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      label(
        canvas,
        marker.label,
        Offset(rect.left + 7, rect.top + (compact ? 4 : 5)),
        color: marker.color,
        fontSize: compact ? 9 : 10,
        weight: FontWeight.w700,
      );
      canvas.drawCircle(marker.position, 5, Paint()..color = Colors.white);
      canvas.drawCircle(marker.position, 3, Paint()..color = marker.color);
    }
  }

  @override
  bool shouldRepaint(covariant _DynoPainter oldDelegate) => true;
}
