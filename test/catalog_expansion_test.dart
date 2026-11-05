import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/dyno_chart.dart';
import 'package:dyno_lab/dyno_data.dart';
import 'package:dyno_lab/main.dart';
import 'package:dyno_lab/share_state.dart';

Map<String, dynamic> comparison(String id, String preset) => {
  'version': 1,
  'metric': 'both',
  'normalizeByWeight': true,
  'includeLoad': false,
  'riderLb': 0.0,
  'gearLb': 0.0,
  'runs': [
    {
      'id': id,
      'weightLb': weightPresets.firstWhere((p) => p.id == preset).weightLb,
      'weightPresetId': preset,
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  test(
    'Every family has a research outcome and matched baselines stay local',
    () {
      expect(tuneResearch.keys.toSet(), bikes.map((b) => b.id).toSet());
      for (final c in configurations.where(
        (c) => c.baselineConfigId.isNotEmpty,
      )) {
        expect(c.baseline, isNotNull, reason: c.id);
        expect(c.baseline!.bikeId, c.bikeId, reason: c.id);
        expect(c.baseline!.upgraded, isFalse, reason: c.id);
        expect(
          c.baseline!.source.asset == c.source.asset ||
              c.baseline!.source.url == c.source.url,
          isTrue,
          reason: '${c.id}: matched runs need linked publisher evidence',
        );
      }
      expect(configById('tuareg-carmo-rally').hasCurve, isFalse);
      expect(configById('tenere-motojp-arrow').hasCurve, isFalse);
      expect(configById('honda-cb500x-reference').hasCurve, isFalse);
    },
  );

  test(
    'Older 373 cc models group together and restored legacy weights remain valid',
    () {
      final adventure = configById('ktm390-adventure-stock-cycleworld-2020');
      final duke = configById('ktm390-duke-rottweiler-pcv-airbox-exhaust');
      expect(adventure.bikeId, duke.bikeId);
      expect(adventure.bikeId, isNot('ktm'));
      const legacy =
          'research-weight-ktm390-duke-mantra-stage2-sport-plus-2016';
      final presets = modelPresetsFor(duke.bikeId, selectedId: legacy);
      expect(
        presets.where((p) => p.label == 'Duke · 373 cc reference'),
        hasLength(1),
      );
      expect(presets.any((p) => p.id == legacy), isTrue);
    },
  );

  testWidgets('KTM 890 variant changes mass and preserves the measured curve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DynoLabApp(
        initialUrlState: encodeSharedState(
          comparison(
            'ktm890-bt-adv-stage1',
            'research-weight-ktm-890-adventure-r-stock',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.widget<DynoChart>(find.byType(DynoChart)).runs.single;
    expect(before.config.bike.fullName, 'KTM 890');
    expect(before.weightLb, 477);
    await tester.tap(find.byKey(const ValueKey('weight-preset-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Adventure · 2023').last);
    await tester.pumpAndSettle();
    final after = tester.widget<DynoChart>(find.byType(DynoChart)).runs.single;
    expect(after.weightLb, 473);
    expect(identical(after.config, before.config), isTrue);
    expect(after.config.peakHp, before.config.peakHp);
    await tester.tap(find.byKey(const ValueKey('add-baseline-0')));
    await tester.pumpAndSettle();
    final runs = tester.widget<DynoChart>(find.byType(DynoChart)).runs;
    expect(runs.map((r) => r.config.id), [
      'ktm890-bt-adv-stage1',
      'ktm890-bt-adv-stock',
    ]);
    expect(runs.map((r) => r.weightLb), [473, 473]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Upgrade coverage and source-only figures fit a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryDialog(
            canAdd: true,
            initialCategory: 'Upgrades',
            initialQuery: 'Tuareg',
            onSelect: (_, _) {},
            onSource: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SOURCE ONLY'), findsAtLeastNWidgets(1));
    await tester.tap(find.textContaining('Research coverage'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
