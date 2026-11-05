import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/dyno_data.dart';
import 'package:dyno_lab/value_format.dart';

void main() {
  test('Average recorded torque with HP-implied torque before deriving HP', () {
    final original = DynoPoint(5000, 102 * 5000 / hpRpmPerNm, 100);
    final adjustment = TorqueReconciliation(original);
    expect(adjustment.impliedTorqueNm, closeTo(102, 1e-10));
    expect(adjustment.torqueDiscrepancyPercent, closeTo(2, 1e-10));
    expect(adjustment.torqueChangePercent, closeTo(1, 1e-10));
    expect(adjustment.requiresReview, isFalse);
    final point = adjustment.apply();
    expect(point.torqueNm, closeTo(101, 1e-10));
    expect(point.hp, closeTo(101 * 5000 / hpRpmPerNm, 1e-10));
    expect(adjustment.hpChangePercent, closeTo(-100 / 102, 1e-10));
    expect(original.torqueNm, 100);
  });

  test(
    'Review gate blocks discrepancies over 5 percent without mutating originals',
    () {
      final original = DynoPoint(5000, 112 * 5000 / hpRpmPerNm, 100);
      final adjustment = TorqueReconciliation(original);
      expect(adjustment.torqueChangePercent, closeTo(6, 1e-10));
      expect(adjustment.requiresReview, isTrue);
      expect(adjustment.apply, throwsStateError);
      expect(original.torqueNm, 100);
      // Even a smaller averaged change is gated if the raw discrepancy is >5%.
      expect(
        TorqueReconciliation(
          DynoPoint(5000, 106 * 5000 / hpRpmPerNm, 100),
        ).requiresReview,
        isTrue,
      );
    },
  );

  test(
    'All current curves meet the gate and obey HP = torque times RPM throughout',
    () {
      var sourcePoints = 0;
      for (final c in configurations) {
        sourcePoints += c.recordedPoints.length;
        for (var i = 0; i < c.recordedPoints.length; i++) {
          final original = c.recordedPoints[i];
          final reconciliation = TorqueReconciliation(original);
          expect(
            reconciliation.requiresReview,
            isFalse,
            reason: '${c.id} at ${original.rpm}',
          );
          expect(
            c.points[i].torqueNm,
            closeTo(
              (original.torqueNm + original.hp * hpRpmPerNm / original.rpm) / 2,
              1e-10,
            ),
          );
        }
        if (!c.hasCurve) continue;
        for (var rpm = c.minRpm; rpm <= c.maxRpm; rpm += 37) {
          final p = c.at(rpm)!;
          expect(
            p.hp,
            closeTo(p.torqueNm * rpm / hpRpmPerNm, 1e-10),
            reason: '${c.id} at $rpm',
          );
        }
      }
      expect(sourcePoints, 807);
      final honda = configById('honda-stock');
      expect(honda.recordedPoints.first.hp, 6.1);
      expect(
        honda.recordedPoints.last.torqueNm / nmPerLbFt,
        closeTo(6.5, 1e-10),
      );
    },
  );

  test(
    'Peak horsepower accounts for the quadratic interior of a torque segment',
    () {
      final c = Configuration(
        id: 'test',
        bikeId: 'honda',
        name: 'Test',
        shortName: 'Test',
        parts: [],
        points: [
          DynoPoint(4000, 100 * 4000 / hpRpmPerNm, 100),
          DynoPoint(8000, 50 * 8000 / hpRpmPerNm, 50),
        ],
        source: configById('honda-stock').source,
        reportedPeaks: '',
        notes: '',
      );
      expect(c.at(6000)!.torqueNm, closeTo(75, 1e-10));
      expect(c.at(6000)!.hp, closeTo(75 * 6000 / hpRpmPerNm, 1e-10));
      expect(c.peakHp, closeTo(c.at(6000)!.hp, 1e-10));
      expect(c.peakHp, greaterThan(c.points.first.hp));
    },
  );

  test('Both ratios use 100 pounds and include the same optional load', () {
    expect(horsepowerPer100Pounds(21, 300), closeTo(7, 1e-10));
    expect(formatValue(horsepowerPer100Pounds(21, 300)), '7.00');
    final total = combinedWeight(
      300,
      riderLb: 180,
      gearLb: 20,
      includeLoad: true,
    );
    expect(horsepowerPer100Pounds(21, total), closeTo(4.2, 1e-10));
    expect(torquePer100Pounds(30 * nmPerLbFt, total), closeTo(6, 1e-10));
  });

  test(
    'Display rounds measurements to three significant figures, retaining zeros',
    () {
      final cases = <num, String>{
        0: '0.00',
        7: '7.00',
        .07: '0.0700',
        .006573126: '0.00657',
        .000012345: '1.23e-5',
        27.87: '27.9',
        363.8: '364',
        999.9: '1000',
        12838: '12800',
        -1.2345: '-1.23',
      };
      for (final entry in cases.entries) {
        expect(formatValue(entry.key), entry.value);
      }
      expect(formatRpm(7511), '7,510');
      expect(
        formatMeasurements(
          '2025 KTM 390: 363.8 lb; 27.87 hp at 8,511 RPM; 0.501087%.',
        ),
        '2025 KTM 390: 364 lb; 27.9 hp at 8,510 RPM; 0.501%.',
      );
    },
  );
}
