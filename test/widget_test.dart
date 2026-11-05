import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/main.dart';
import 'package:dyno_lab/dyno_chart.dart';
import 'package:dyno_lab/dyno_data.dart';

Future<void> enableNormalization(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('normalize-weight'));
  await tester.ensureVisible(toggle);
  if (!tester.widget<Switch>(toggle).value) await tester.tap(toggle);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  test(
    'Older saved weights migrate and explicit custom weights stay custom',
    () {
      expect(
        Selection('honda-stock', weightLb: 309).weightPresetId,
        'honda-standard',
      );
      expect(Selection('honda-stock', weightLb: 321).weightPresetId, 'custom');
      expect(
        Selection(
          'honda-stock',
          weightLb: 309,
          weightPresetId: 'custom',
        ).weightPresetId,
        'custom',
      );
      final enduro = Selection('ktm-stock', weightPresetId: 'ktm-enduro');
      expect(enduro.weightLb, 363.8);
      expect(enduro.weightPresetId, 'ktm-enduro');
    },
  );
  testWidgets(
    'Rider and gear inputs show whole pounds and round decimal entries',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      await tester.pumpWidget(DynoLabApp(onStateChanged: (s) => saved = s));
      await tester.pumpAndSettle();
      final rider = find.byKey(const ValueKey('rider-weight'));
      final gear = find.byKey(const ValueKey('gear-weight'));
      expect(tester.widget<TextField>(rider).controller!.text, '0');
      expect(tester.widget<TextField>(gear).controller!.text, '0');
      expect(
        tester.widget<TextField>(rider).keyboardType,
        TextInputType.number,
      );
      await tester.tap(find.byKey(const ValueKey('include-load')));
      await tester.pumpAndSettle();
      await tester.enterText(rider, '180.5');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.enterText(gear, '19.49');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(rider).controller!.text, '181');
      expect(tester.widget<TextField>(gear).controller!.text, '19');
      expect(saved!['riderLb'], 181);
      expect(saved!['gearLb'], 19);
      expect(
        tester
            .widget<DynoChart>(find.byType(DynoChart))
            .runs
            .map((r) => r.totalWeightLb),
        [509, 588],
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Shared rider and gear load updates every bike and toggles without losing values',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('include-load')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('rider-weight')), '180');
      await tester.enterText(find.byKey(const ValueKey('gear-weight')), '20');
      await tester.pumpAndSettle();
      var chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.metric, Metric.both);
      expect(chart.normalizeByWeight, isTrue);
      expect(chart.runs.map((r) => r.totalWeightLb), [509, 588]);
      expect(
        chart.runs.first.hpPerLbAt(6000),
        closeTo(20.103096544222193 / 509, 1e-10),
      );
      expect(
        chart.runs.first.config.at(6000)!.hp,
        closeTo(20.103096544222193, 1e-10),
      );
      await tester.enterText(find.byKey(const ValueKey('gear-weight')), '-5');
      await tester.pumpAndSettle();
      expect(find.text('Use zero or a positive weight'), findsOneWidget);
      expect(
        tester
            .widget<DynoChart>(find.byType(DynoChart))
            .runs
            .first
            .totalWeightLb,
        509,
      );
      await tester.tap(find.byKey(const ValueKey('include-load')));
      await tester.pumpAndSettle();
      chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.runs.map((r) => r.totalWeightLb), [309, 388]);
      await tester.tap(find.byKey(const ValueKey('include-load')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DynoChart>(find.byType(DynoChart))
            .runs
            .map((r) => r.totalWeightLb),
        [509, 588],
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Rally and Enduro presets apply independently and custom edits remain available',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weight-preset-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rally · 333 lb').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('weight-preset-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enduro R · 364 lb').last);
      await tester.pumpAndSettle();
      var chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.runs.map((r) => r.weightLb), [333, 363.8]);
      expect(chart.runs.map((r) => r.config.id), ['honda-stock', 'ktm-stock']);
      expect(chart.runs.map((r) => r.weightLabel), ['Rally', 'Enduro R']);
      await tester.enterText(find.byKey(const ValueKey('weight-0')), '320');
      await tester.pumpAndSettle();
      chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.runs.first.weightLabel, 'Custom');
      expect(chart.runs.first.weightLb, 320);
      expect(chart.runs.last.weightLb, 363.8);
      await tester.enterText(
        find.byKey(const ValueKey('weight-0')),
        '320.1234',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('weight-0')))
            .controller!
            .text,
        '320',
      );
      expect(
        tester.widget<DynoChart>(find.byType(DynoChart)).runs.first.weightLb,
        320.1234,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'One per-100-pound switch normalizes both power and torque and preserves metric choice',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('weight-0')), '300');
      await enableNormalization(tester);
      expect(
        tester.widget<DynoChart>(find.byType(DynoChart)).normalizeByWeight,
        isTrue,
      );
      expect(find.text('PEAK TORQUE / 100 LB ≈'), findsNWidgets(2));
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == '5.87 lb-ft/100 lb',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Torque').first);
      await tester.tap(find.text('Torque').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<DynoChart>(find.byType(DynoChart)).metric,
        Metric.torque,
      );
      await tester.tap(find.byKey(const ValueKey('normalize-weight')));
      await tester.pumpAndSettle();
      final chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.normalizeByWeight, isFalse);
      expect(chart.metric, Metric.torque);
      expect(find.text('PEAK TORQUE ≈'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  test('Identical bikes can use independent weights on one shared scale', () {
    final config = configById('honda-stock');
    final a = ChartRun(config, Colors.blue, 'A', weightLb: 300);
    final b = ChartRun(config, Colors.orange, 'B', weightLb: 600);
    expect(a.hpPerLbAt(6000), closeTo(b.hpPerLbAt(6000)! * 2, 1e-10));
    expect(a.hpPerLbAt(2000), isNull);
    expect(
      powerToWeightAxisMax([a, b]),
      greaterThanOrEqualTo(a.peakHpPer100Lb),
    );
    expect(powerToWeightAxisMax([b]), lessThan(powerToWeightAxisMax([a])));
  });
  testWidgets(
    'Power-to-weight mode recalculates after a valid weight edit and rejects zero',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('weight-0')), '300');
      await tester.pumpAndSettle();
      await enableNormalization(tester);
      var chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.metric, Metric.both);
      expect(chart.normalizeByWeight, isTrue);
      expect(
        chart.runs.first.hpPerLbAt(6000),
        closeTo(20.103096544222193 / 300, 1e-10),
      );
      expect(chart.runs[1].weightLb, 388);
      await tester.ensureVisible(find.byKey(const ValueKey('weight-0')));
      await tester.enterText(find.byKey(const ValueKey('weight-0')), '0');
      await tester.pumpAndSettle();
      chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.runs.first.weightLb, 300);
      expect(find.textContaining('Enter a positive weight'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('weight-0')), '600');
      await tester.pumpAndSettle();
      chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(
        chart.runs.first.hpPerLbAt(6000),
        closeTo(20.103096544222193 / 600, 1e-10),
      );
      expect(find.textContaining('Enter a positive weight'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Comparison page fits desktop and narrow mobile screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [1440.0, 768.0, 390.0, 320.0]) {
      tester.view.physicalSize = Size(width, 1100);
      await tester.pumpWidget(const DynoLabApp());
      await tester.pumpAndSettle();
      expect(find.text('Power, put in perspective.'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Layout at width $width');
      await tester.ensureVisible(find.byKey(const ValueKey('include-load')));
      final load = tester.widget<Switch>(
        find.byKey(const ValueKey('include-load')),
      );
      if (!load.value) {
        await tester.tap(find.byKey(const ValueKey('include-load')));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byKey(const ValueKey('rider-weight')), '180');
      await tester.enterText(find.byKey(const ValueKey('gear-weight')), '20');
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Shared load at width $width',
      );
      await enableNormalization(tester);
      expect(
        tester.widget<DynoChart>(find.byType(DynoChart)).normalizeByWeight,
        isTrue,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Power-to-weight at width $width',
      );
    }
  });
  testWidgets('Adding runs and same-bike presets work', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const DynoLabApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add comparison'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bike-2')), findsOneWidget);
    await tester.tap(find.text('Add comparison'));
    await tester.pumpAndSettle();
    expect(find.text('4 comparisons added'), findsOneWidget);
    final preset = find.text('CRF300L: stock vs. Stage 1.0');
    await tester.ensureVisible(preset);
    await tester.tap(preset);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bike-2')), findsNothing);
    final chart = tester.widget<DynoChart>(find.byType(DynoChart));
    expect(chart.runs.map((r) => r.config.id), ['honda-stock', 'honda-stage1']);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Shared hover and touch marker tracks RPM and stays after release',
    (tester) async {
      var rpm = 6000.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) => DynoChart(
                    runs: [
                      ChartRun(configById('honda-stock'), Colors.blue, 'A'),
                    ],
                    rpm: rpm,
                    metric: Metric.both,
                    onRpm: (r) => setState(() => rpm = r),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(DynoChart));
      final plot = DynoChart.plot(box.size);
      final at7500 =
          box.topLeft + Offset(plot.left + plot.width * .625, plot.center.dy);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at7500);
      await mouse.moveTo(at7500);
      await tester.pump();
      expect(rpm, closeTo(7500, 1));
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      final touch =
          box.topLeft + Offset(plot.left + plot.width * .5, plot.center.dy);
      await tester.tapAt(touch);
      await tester.pump();
      expect(rpm, closeTo(6500, 1));
      await tester.pump(const Duration(seconds: 1));
      expect(rpm, closeTo(6500, 1));
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
    },
  );
}
