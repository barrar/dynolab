import 'dart:math' as math;

/// Three significant figures for display; calculations retain their precision.
String formatValue(num number) {
  final value = number.toDouble();
  if (!value.isFinite) return '—';
  if (value == 0) return '0.00';
  final rounded = double.parse(value.toStringAsPrecision(3));
  final exponent = (math.log(rounded.abs()) / math.ln10 + 1e-12).floor();
  if (exponent < -3 || exponent >= 6) {
    return rounded.toStringAsExponential(2).replaceFirst('e+', 'e');
  }
  return rounded.toStringAsFixed(math.max(0, 2 - exponent));
}

String formatRpm(num value) {
  final text = formatValue(value);
  if (text.contains('e')) return text;
  final parts = text.split('.');
  parts[0] = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return parts.join('.');
}

/// Round measurements inside prose while preserving model names and years.
String formatMeasurements(String text) => text.replaceAllMapped(
  RegExp(
    r'(\d[\d,]*(?:\.\d+)?)\s*(whp|bhp|hp|lb-ft|N·m|Nm|RPM|rpm|pounds|lb|kg|cc|PS|%)(?![A-Za-z])',
  ),
  (match) {
    final value = double.tryParse(match[1]!.replaceAll(',', ''));
    if (value == null) return match[0]!;
    final unit = match[2]!;
    return '${unit.toLowerCase() == 'rpm' ? formatRpm(value) : formatValue(value)}${unit == '%' ? '' : ' '}$unit';
  },
);
