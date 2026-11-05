import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/dyno_data.dart';
import 'package:dyno_lab/dyno_chart.dart';
import 'package:dyno_lab/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  test(
    'Both editorial collections have ten unique picks linked to real configurations',
    () {
      for (final picks in [adventurePicks, dualSportPicks]) {
        expect(picks, hasLength(10));
        expect(picks.map((p) => p.title).toSet(), hasLength(10));
        for (final pick in picks) {
          expect(configurations.any((c) => c.id == pick.configId), isTrue);
          expect(configById(pick.configId).hasCurve, isTrue);
        }
      }
    },
  );
  test(
    'Every researched curve has sane ascending samples and a valid default weight',
    () {
      for (final c in configurations) {
        expect(c.source.url, startsWith('https://'));
        if (!c.hasCurve) {
          expect(c.at(6000), isNull);
          continue;
        }
        expect(c.defaultWeight.weightLb, greaterThan(0));
        for (var i = 0; i < c.points.length; i++) {
          final p = c.points[i];
          expect(p.hp.isFinite && p.torqueNm.isFinite, isTrue);
          if (i > 0) expect(p.rpm, greaterThan(c.points[i - 1].rpm));
        }
      }
      final cbr = configurations.firstWhere(
        (c) => c.bike.name.contains('CBR650R'),
      );
      expect(
        DynoChart.maxFor([ChartRun(cbr, Colors.blue, 'A')]),
        greaterThanOrEqualTo(12500),
      );
    },
  );
  test(
    'Older KTM curves and documented hardware kits stay separate from the 399 cc platform',
    () {
      final stock = configById('ktm390-adventure-stock-cycleworld-2020');
      final mapped = configById('ktm390-duke-rottweiler-pcv-airbox-exhaust');
      expect(stock.hasCurve && mapped.hasCurve, isTrue);
      expect(stock.bikeId, isNot('ktm'));
      expect(mapped.bikeId, isNot('ktm'));
      expect(stock.bike.displacement, contains('373'));
      for (final id in [
        'ktm390-duke-brperformance-stage2',
        'ktm390-duke-mantra-stage2-sport-plus-2016',
        'ktm390-duke-ecuwest-remap-2016',
      ]) {
        expect(configById(id).hasCurve, isFalse);
      }
      expect(mapped.parts.join(' ').toLowerCase(), contains('airbox'));
    },
  );
  test('CRF300F is a real catalog entry without a fabricated dyno curve', () {
    final c = configurations.firstWhere((c) => c.bike.name == 'CRF300F');
    expect(c.category, 'Off-road');
    expect(c.hasCurve, isFalse);
    expect(c.points, isEmpty);
    expect(c.bike.referenceWeightLb, 271);
  });
  testWidgets(
    'Expanded library searches requested models and marks source-only entries',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dyno library'));
      await tester.pumpAndSettle();
      expect(find.text('Adventure · 10'), findsOneWidget);
      expect(find.text('Dual sport · 10'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('library-search')),
        'CRF300F',
      );
      await tester.pumpAndSettle();
      expect(find.text('Honda CRF300F'), findsOneWidget);
      expect(find.text('SOURCE ONLY'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'No RPM curve to plot'),
      );
      expect(button.onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('library-search')),
        'CBR650R',
      );
      await tester.pumpAndSettle();
      expect(find.text('Honda CBR650R'), findsOneWidget);
      expect(find.text('CURVE READY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('The library fits a mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: LibraryDialog(
              canAdd: true,
              onSelect: (_, _) {},
              onSource: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
