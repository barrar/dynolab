import 'dart:convert';
import 'dart:io';
import 'package:dyno_lab/dyno_data.dart';
import 'package:dyno_lab/value_format.dart';

void main() {
  // Always audit immutable source samples, never already-reconciled points.
  final curves = configurations.where((c) => c.recordedPoints.length >= 2);
  final rows = <Map<String, Object?>>[];
  final summaries = <Map<String, Object?>>[];
  for (final c in curves) {
    final points = <Map<String, Object?>>[];
    final adjusted = <DynoPoint>[];
    for (final p in c.recordedPoints) {
      final a = TorqueReconciliation(p);
      adjusted.add(DynoPoint(p.rpm, a.calculatedHp, a.averagedTorqueNm));
      points.add({
        'configurationId': c.id,
        'bike': c.bike.fullName,
        'configuration': c.name,
        'rpm': p.rpm,
        'recordedHp': p.hp,
        'recordedTorqueNm': p.torqueNm,
        'torqueImpliedByHpNm': a.impliedTorqueNm,
        'adjustedTorqueNm': a.averagedTorqueNm,
        'calculatedHp': a.calculatedHp,
        'torqueDiscrepancyPercent': a.torqueDiscrepancyPercent,
        'torqueChangePercent': a.torqueChangePercent,
        'hpChangePercent': a.hpChangePercent,
        'requiresReview': a.requiresReview,
      });
    }
    rows.addAll(points);
    Map<String, Object?> largest(String key) => points.reduce(
      (a, b) => (a[key] as double).abs() >= (b[key] as double).abs() ? a : b,
    );
    // Compare the new physical HP curve with the old linear-HP interpolation.
    var maxInterpolatedChange = 0.0;
    var maxInterpolatedRpm = c.recordedPoints.first.rpm;
    for (var i = 1; i < c.recordedPoints.length; i++) {
      final a = c.recordedPoints[i - 1], b = c.recordedPoints[i];
      for (var rpm = a.rpm; rpm <= b.rpm; rpm += 1) {
        final fraction = (rpm - a.rpm) / (b.rpm - a.rpm);
        final oldHp = a.hp + (b.hp - a.hp) * fraction;
        final torque =
            adjusted[i - 1].torqueNm +
            (adjusted[i].torqueNm - adjusted[i - 1].torqueNm) * fraction;
        final hp = horsepowerFromTorque(torque, rpm);
        final change = (hp - oldHp) / oldHp * 100;
        if (change.abs() > maxInterpolatedChange.abs()) {
          maxInterpolatedChange = change;
          maxInterpolatedRpm = rpm;
        }
      }
    }
    final torqueMax = largest('torqueChangePercent');
    summaries.add({
      'configurationId': c.id,
      'bike': c.bike.fullName,
      'configuration': c.name,
      'pointCount': points.length,
      'changedPointsAboveNumericalNoise': points
          .where((r) => (r['torqueChangePercent'] as double).abs() > 1e-6)
          .length,
      'maxTorqueDiscrepancyPercent':
          (largest('torqueDiscrepancyPercent')['torqueDiscrepancyPercent']
                  as double)
              .abs(),
      'maxTorqueChangePercent': torqueMax['torqueChangePercent'],
      'maxTorqueChangeRpm': torqueMax['rpm'],
      'maxHpChangePercent':
          (largest('hpChangePercent')['hpChangePercent'] as double).abs(),
      'maxInterpolatedHpChangePercent': maxInterpolatedChange,
      'maxInterpolatedHpChangeRpm': maxInterpolatedRpm,
      'reviewPoints': points.where((r) => r['requiresReview'] == true).length,
    });
  }
  final reviewPoints = rows.where((r) => r['requiresReview'] == true).toList();
  final intermediateReview = summaries
      .where((s) => (s['maxInterpolatedHpChangePercent'] as double).abs() > 5)
      .toList();
  final needsReview = reviewPoints.isNotEmpty || intermediateReview.isNotEmpty;
  final report = {
    'status': needsReview
        ? 'Review required before applying'
        : 'Applied to derived app curves; original samples preserved',
    'method':
        'impliedTorqueNm = recordedHp * 7120.9092 / rpm; adjustedTorqueNm = (recordedTorqueNm + impliedTorqueNm) / 2; calculatedHp = adjustedTorqueNm * rpm / 7120.9092. Between samples, interpolate adjusted torque and derive HP from torque and RPM.',
    'percentBaseline':
        'Each percentage uses its recorded value as denominator. Conservative review flags cover any raw torque discrepancy, averaged torque adjustment, or resulting horsepower adjustment over 5%. Intermediate HP is compared with the previous linear-HP curve at 1 RPM intervals.',
    'display':
        'Three significant figures; full-precision original and calculated values are retained in this JSON.',
    'curves': summaries,
    'points': rows,
  };
  File('docs/dyno-consistency-audit.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  String percent(num value, {bool signed = false}) =>
      '${signed && value > 0 ? '+' : ''}${formatValue(value)}%';
  final lines = <String>[
    '# Torque and horsepower consistency audit',
    '',
    '**${report['status']}.** ${rows.length} source points across ${summaries.length} curves; ${reviewPoints.length} points and ${intermediateReview.length} interpolated curves exceed the conservative 5.00% review threshold.',
    '',
    'For each source point, convert recorded horsepower to torque using its RPM, average that result with the recorded torque, and derive horsepower from the average. Between samples, interpolate torque and calculate horsepower from torque and RPM. No original source samples or publisher charts are overwritten.',
    '',
    'Percent changes use the recorded torque or horsepower as the baseline. The review gate also checks the raw torque discrepancy before averaging. All table measurements use three significant figures. The JSON preserves full precision. Interpolated HP differences compare with the previous linear-HP curve at 1 RPM intervals.',
    '',
    '## Changes by curve',
    '',
    'Maximum torque adjustments are signed; raw discrepancies and source-point HP changes are absolute maxima. Tiny differences can result from the source dataset rounding previously derived torque.',
    '',
    '| Bike / run | Samples | Max raw torque discrepancy | Max torque adjustment | RPM of torque adjustment | Max source-point HP change | Max HP change including interpolation |',
    '| --- | ---: | ---: | ---: | ---: | ---: | ---: |',
    for (final s in summaries)
      '| ${s['bike']} / ${s['configuration']} | ${s['pointCount']} | ${percent(s['maxTorqueDiscrepancyPercent'] as num)} | ${percent(s['maxTorqueChangePercent'] as num, signed: true)} | ${formatRpm(s['maxTorqueChangeRpm'] as num)} | ${percent(s['maxHpChangePercent'] as num)} | ${percent(s['maxInterpolatedHpChangePercent'] as num, signed: true)} |',
    '',
    '## Review gate',
    '',
    needsReview
        ? 'Changes above the threshold require user review before application. Inspect the JSON review flags.'
        : 'No changes exceed 5.00%, including the raw torque discrepancies before averaging. No additional approval was required.',
    '',
    'The [per-point CSV](dyno-consistency-points.csv) includes every original value, horsepower-implied torque, averaged torque, calculated horsepower, and signed percentage change. The [JSON](dyno-consistency-audit.json) retains full precision. Rounding the displayed measurements can conceal very small adjustments.',
    '',
    '## Display and weight normalization',
    '',
    'All app measurements and comparison CSV values display three significant figures. Model names, model years, collection counts, and the original published chart images retain their identifying content. Calculations and saved weights keep full precision.',
    '',
    'The single **Per 100 lb** switch applies `100 × horsepower / total lb` and `100 × torque / total lb` to both metrics. Total weight includes the optional shared rider and gear weights. For example, 0.0700 hp/lb becomes 7.00 hp/100 lb.',
  ];
  File(
    'docs/dyno-consistency-audit.md',
  ).writeAsStringSync('${lines.join('\n')}\n');
  final keys = [
    'configurationId',
    'rpm',
    'recordedHp',
    'recordedTorqueNm',
    'torqueImpliedByHpNm',
    'adjustedTorqueNm',
    'calculatedHp',
    'torqueDiscrepancyPercent',
    'torqueChangePercent',
    'hpChangePercent',
    'requiresReview',
  ];
  final csv =
      <List<String>>[
            keys,
            for (final r in rows)
              [
                for (final key in keys)
                  r[key] is num ? formatValue(r[key] as num) : '${r[key]}',
              ],
          ]
          .map(
            (row) => row.map((v) => '"${v.replaceAll('"', '""')}"').join(','),
          )
          .join('\r\n');
  File('docs/dyno-consistency-points.csv').writeAsStringSync('$csv\r\n');
  stdout.writeln(
    jsonEncode({
      'points': rows.length,
      'curves': summaries.length,
      'reviewPoints': reviewPoints.length,
      'intermediateReview': intermediateReview.length,
      'status': report['status'],
    }),
  );
  if (needsReview) exitCode = 2;
}
