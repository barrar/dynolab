import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/dyno_data.dart';

void main() {
  test(
    'Torque per pound uses pound-feet and uses the same total denominator',
    () {
      final p = configById('honda-stock').at(6000)!;
      final total = combinedWeight(
        309,
        riderLb: 180,
        gearLb: 20,
        includeLoad: true,
      );
      expect(
        torquePerPound(p.torqueNm, total),
        closeTo(17.59728943325717 / 509, 1e-10),
      );
      expect(() => torquePerPound(p.torqueNm, 0), throwsArgumentError);
    },
  );
  test('Optional rider and gear are added exactly once to each bike', () {
    expect(combinedWeight(309, riderLb: 180, gearLb: 20), 309);
    expect(
      combinedWeight(309, riderLb: 180, gearLb: 20, includeLoad: true),
      509,
    );
    expect(
      combinedWeight(388, riderLb: 180, gearLb: 20, includeLoad: true),
      588,
    );
    expect(combinedWeight(309, includeLoad: true), 309);
    expect(isValidLoadWeight(0), isTrue);
    expect(isValidLoadWeight(-1), isFalse);
    expect(
      () => combinedWeight(309, riderLb: double.infinity),
      throwsArgumentError,
    );
  });
  test('Model weights use wet references and keep the KTM family name', () {
    expect(bikes.firstWhere((b) => b.id == 'ktm').fullName, 'KTM 390');
    expect(weightPresetsFor('honda').map((p) => p.weightLb), [
      309,
      311,
      333,
      337,
    ]);
    expect(weightPresetsFor('ktm').map((p) => p.weightLb), [388, 363.8]);
    expect(
      weightPresets.every((p) => p.sourceUrl.startsWith('https://')),
      isTrue,
    );
  });
  test(
    'Power per pound divides power, not RPM or engine torque, by weight',
    () {
      final point = configById('honda-stock').at(6000)!;
      expect(
        horsepowerPerPound(point.hp, 300),
        closeTo(20.103096544222193 / 300, 1e-10),
      );
      expect(
        horsepowerPerPound(point.hp, 600),
        closeTo(20.103096544222193 / 600, 1e-10),
      );
      expect(point.hp, closeTo(20.103096544222193, 1e-10));
    },
  );
  test('Zero, negative and non-finite weights are rejected', () {
    for (final value in [0.0, -10.0, double.nan, double.infinity]) {
      expect(isValidWeight(value), isFalse);
      expect(() => horsepowerPerPound(20, value), throwsArgumentError);
    }
    expect(isValidWeight(null), isFalse);
  });
  test('Interpolation remains within source domain', () {
    final stock = configById('honda-stock');
    expect(stock.at(2499), isNull);
    expect(stock.at(10401), isNull);
    expect(
      stock.at(2500)!.torqueNm,
      closeTo(stock.points.first.torqueNm, 1e-10),
    );
    expect(
      stock.at(6250)!.torqueNm,
      closeTo((stock.at(6000)!.torqueNm + stock.at(6500)!.torqueNm) / 2, 1e-10),
    );
    expect(stock.at(10400)!.hp, closeTo(12.9355049847483, 1e-10));
  });
  test(
    'Original samples preserve the Honda units while plotted torque is reconciled',
    () {
      final p = configById(
        'honda-stock',
      ).recordedPoints.firstWhere((p) => p.rpm == 6500);
      expect(torqueLbFt(p.torqueNm), closeTo(17.9, 1e-8));
      expect(p.torqueNm, closeTo(24.26914, .0001));
    },
  );
  test('KTM horsepower is physically consistent with digitized torque', () {
    for (final c in configurations.where((c) => c.bikeId == 'ktm')) {
      for (final p in c.points) {
        expect(p.hp, closeTo(p.torqueNm * p.rpm / hpRpmPerNm, 1e-9));
      }
      expect(c.source.caveat, contains('without specifying Adventure R'));
    }
  });
  test(
    'Each bike has a stock and hardware-matched ECU upgrade configuration',
    () {
      for (final bike in bikes.where((b) => b.id == 'honda' || b.id == 'ktm')) {
        final builds = configurations.where((c) => c.bikeId == bike.id);
        expect(builds.any((c) => !c.upgraded), isTrue);
        expect(builds.any((c) => c.upgraded), isTrue);
        for (final build in builds) {
          expect(build.source.url, startsWith('https://'));
          for (var i = 1; i < build.points.length; i++) {
            expect(build.points[i].rpm, greaterThan(build.points[i - 1].rpm));
          }
        }
      }
    },
  );
}
