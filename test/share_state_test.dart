import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dyno_lab/main.dart';
import 'package:dyno_lab/dyno_chart.dart';
import 'package:dyno_lab/dyno_data.dart';
import 'package:dyno_lab/share_state.dart';
import 'package:dyno_lab/share_catalog.dart';

Map<String, dynamic> fixture() => {
  'version': 1,
  'metric': 'torque',
  'normalizeByWeight': true,
  'includeLoad': true,
  'riderLb': 182.0,
  'gearLb': 23.0,
  'runs': [
    {'id': 'honda-stage1', 'weightLb': 320.1234, 'weightPresetId': 'custom'},
    {'id': 'ktm-stock', 'weightLb': 363.8, 'weightPresetId': 'ktm-enduro'},
    {'id': 'honda-stock', 'weightLb': 333.0, 'weightPresetId': 'honda-rally'},
    {'id': 'ktm-coober', 'weightLb': 388.0, 'weightPresetId': 'ktm-adventure'},
  ],
};

String packet(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });

  test(
    'Shared links preserve ordered builds, presets, and exact custom weights',
    () {
      final state = fixture();
      final encoded = encodeSharedState(state);
      expect(encoded, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      expect(decodeSharedState(encoded), state);
      expect(encoded.length, lessThan(30));
    },
  );

  test(
    'Colors, units, visibility, view state, cursor, and scroll use no URL bytes',
    () {
      final state = fixture();
      final before = encodeSharedState(state);
      state['unit'] = 'nm';
      state['rpm'] = 7500;
      state['scroll'] = 999;
      state['view'] = {
        'panel': 'library',
        'sourceId': 'honda-stage1',
        'category': 'Requested',
        'query': 'ＫＴＭ 🏍️ + # & 日本語' * 100,
      };
      for (var i = 0; i < 4; i++) {
        state['runs'][i]['color'] = 3 - i;
        state['runs'][i]['visible'] = false;
      }
      expect(encodeSharedState(state), before);
      expect(decodeSharedState(before), fixture());
      // Even malformed discarded fields cannot affect or invalidate the link.
      state['unit'] = <String>[];
      state['view'] = 'unused';
      state['runs'][0]['color'] = 'unused';
      expect(encodeSharedState(state), before);
    },
  );

  test(
    'URLs use one path segment, remove old state, and preserve unrelated values',
    () {
      final encoded = encodeSharedState(fixture());
      final url = urlWithSharedState(
        Uri.parse(
          'https://moto.bendtrailmaps.com/old?s=old&state=old&campaign=demo&tag=a&tag=b#section',
        ),
        encoded,
      );
      expect(url.host, 'moto.bendtrailmaps.com');
      expect(url.pathSegments, [encoded]);
      expect(url.queryParametersAll['tag'], ['a', 'b']);
      expect(url.queryParameters['campaign'], 'demo');
      expect(url.queryParameters.containsKey('s'), isFalse);
      expect(url.queryParameters.containsKey('state'), isFalse);
      expect(url.fragment, 'section');
      expect(decodeSharedState(sharedStateFromUrl(url)), fixture());
      final local = urlWithSharedState(
        Uri.parse('http://127.0.0.1:52741/'),
        encoded,
      );
      expect(local.toString(), 'http://127.0.0.1:52741/$encoded');
      expect(local.hasQuery, isFalse);
      for (final path in ['/', '/a/b', '/?s=old&state=old']) {
        expect(
          sharedStateFromUrl(Uri.parse('https://moto.bendtrailmaps.com$path')),
          isNull,
        );
      }
    },
  );

  test('Invalid comparison settings cannot be encoded', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (s) => s['version'] = 2,
      (s) => s['runs'] = [],
      (s) => s['runs'][0]['id'] = 'unknown-bike',
      (s) => s['runs'][0]['weightLb'] = 0,
      (s) => s['runs'][0]['weightLb'] = -100,
      (s) => s['runs'][0]['weightLb'] = double.infinity,
      (s) => s['runs'][0]['weightPresetId'] = 'ktm-enduro',
      (s) => s['metric'] = 'unknown',
      (s) => s['riderLb'] = -1,
      (s) => s['includeLoad'] = 'yes',
    ]) {
      final state = fixture();
      mutate(state);
      expect(() => encodeSharedState(state), throwsArgumentError);
    }
    final state = fixture();
    state['runs'][0]['id'] = configurations.firstWhere((c) => !c.hasCurve).id;
    expect(() => encodeSharedState(state), throwsArgumentError);
  });

  test('Preset packets contain only options and numeric build/preset IDs', () {
    final state = fixture();
    state['riderLb'] = 0.0;
    state['gearLb'] = 0.0;
    state['runs'] = [state['runs'][1], state['runs'][2]];
    final bytes = base64Url.decode(
      base64Url.normalize(encodeSharedState(state)),
    );
    expect(bytes.length, 4);
    expect(decodeSharedState(encodeSharedState(state)), state);
  });

  test('Permanent numeric codebooks cover every current build and preset', () {
    expect(
      sharedConfigurationIds.toSet().length,
      sharedConfigurationIds.length,
    );
    expect(sharedConfigurationIds.take(4), [
      'honda-stock',
      'honda-stage1',
      'ktm-stock',
      'ktm-coober',
    ]);
    expect(sharedWeightReferences.take(6).map((p) => p.id), [
      'honda-standard',
      'honda-abs',
      'honda-rally',
      'honda-rally-abs',
      'ktm-adventure',
      'ktm-enduro',
    ]);
    for (final c in configurations) {
      expect(sharedConfigurationIds, contains(c.id));
    }
    for (final p in weightPresets) {
      expect(
        sharedWeightReferences.any(
          (wire) => wire.id == p.id && wire.weightLb == p.weightLb,
        ),
        isTrue,
        reason: 'Append the new preset reference: ${p.id}',
      );
    }
    for (final c in configurations.where((c) => c.hasCurve)) {
      for (final p in weightPresetsFor(c.bikeId).where((p) => p.weightLb > 0)) {
        final state = fixture();
        state['runs'] = [
          {'id': c.id, 'weightLb': p.weightLb, 'weightPresetId': p.id},
        ];
        expect(decodeSharedState(encodeSharedState(state)), state);
      }
    }
  });

  test(
    'Custom bike weights retain exact decimal and binary float precision',
    () {
      for (final weight in [
        0.1,
        20.125,
        320.1234,
        363.8,
        1.0000000000000002,
        20.1234567890123,
        1e100,
        double.minPositive,
      ]) {
        final state = fixture();
        state['runs'][0]['weightLb'] = weight;
        expect(
          decodeSharedState(encodeSharedState(state))!['runs'][0]['weightLb'],
          weight,
        );
      }
    },
  );

  test(
    'The decoder reads complete comparisons to the end, without a count',
    () {
      for (var count = 1; count <= 4; count++) {
        final bytes = [0, ...List.filled(count, 96)];
        final state = decodeSharedState(packet(bytes))!;
        expect(state['runs'], hasLength(count));
        expect(state['runs'].every((r) => r['id'] == 'honda-stock'), isTrue);
        expect(encodeSharedState(state), packet(bytes));
      }
      expect(decodeSharedState(packet([0])), isNull);
      expect(decodeSharedState(packet([0, ...List.filled(5, 96)])), isNull);
      for (final partial in <List<int>>[
        [0, 0], // Custom weight is missing.
        [0, 0, 128], // Custom weight stops inside a number.
        [0, 96, 194], // Next entry stops inside its packed ID.
        [0, 96, 31], // Extended configuration code is missing.
      ]) {
        expect(decodeSharedState(packet(partial)), isNull);
      }
    },
  );

  test(
    'Malformed settings and partial trailing comparisons are silently ignored',
    () {
      for (final value in [null, '', 'not-a-valid-payload', 'x' * 16001]) {
        expect(decodeSharedState(value), isNull);
      }
      final encoded = encodeSharedState(fixture());
      final bytes = base64Url.decode(base64Url.normalize(encoded));
      for (var length = 0; length < bytes.length; length++) {
        final restored = decodeSharedState(packet(bytes.sublist(0, length)));
        if (restored != null) {
          // Truncation at a complete entry is now a valid shorter comparison.
          expect(
            restored['runs'],
            fixture()['runs'].take((restored['runs'] as List).length).toList(),
          );
          expect({...restored, 'runs': []}, {...fixture(), 'runs': []});
        }
      }
      for (final invalid in <List<int>>[
        [3], // Undefined metric.
        [64], // Undefined option bit.
        [128, 0], // Noncanonical integer.
        [0, 30], // Unknown configuration.
        [0, 31, 100], // Unknown extended configuration.
        [0, 128, 126], // Unknown preset.
        [0, 160, 1], // KTM preset on a Honda.
        [0, 0, 0], // Zero custom weight.
        [...bytes, 0], // Unused trailing data.
      ]) {
        expect(decodeSharedState(packet(invalid)), isNull);
      }
      expect(decodeSharedState('$encoded='), isNull);
      expect(
        decodeSharedState(
          '${encoded.substring(0, 1)}%20${encoded.substring(1)}',
        ),
        isNull,
      );
    },
  );

  test(
    'Minimal fixture has no count, color, unit, view, version, or checksum bytes',
    () {
      final state = decodeSharedState('AGDCAQ')!;
      expect(state['runs'].map((r) => r['id']), ['honda-stock', 'ktm-stock']);
      expect(state['runs'].map((r) => r['weightPresetId']), [
        'honda-rally',
        'ktm-enduro',
      ]);
      expect(state['runs'].map((r) => r['weightLb']), [333.0, 363.8]);
      expect(state['includeLoad'], isFalse);
      expect(state['normalizeByWeight'], isFalse);
      expect(encodeSharedState(state), 'AGDCAQ');
    },
  );

  testWidgets(
    'Shared comparisons use default colors and pound-feet, without sharing cursor or visibility',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        DynoLabApp(
          initialUrlState: encodeSharedState(fixture()),
          onStateChanged: (s) => saved = s,
        ),
      );
      await tester.pumpAndSettle();
      final chart = tester.widget<DynoChart>(find.byType(DynoChart));
      expect(chart.metric, Metric.torque);
      expect(chart.normalizeByWeight, isTrue);
      expect(chart.runs.map((r) => r.config.id), [
        'honda-stage1',
        'ktm-stock',
        'honda-stock',
        'ktm-coober',
      ]);
      expect(chart.runs.map((r) => r.totalWeightLb), [
        525.1234,
        568.8,
        538.0,
        593.0,
      ]);
      expect(chart.runs.map((r) => r.letter), ['A', 'B', 'C', 'D']);
      expect(chart.runs.map((r) => r.color), palette);
      expect(find.textContaining('lb-ft', findRichText: true), findsWidgets);
      expect(find.text('N·m'), findsNothing);
      expect(saved!.containsKey('unit'), isFalse);
      expect(saved!['runs'].every((r) => !r.containsKey('color')), isTrue);
      expect(decodeSharedState(encodeSharedState(saved!)), fixture());
      final before = encodeSharedState(saved!);
      await tester.tap(find.byTooltip('Show or hide both curves').first);
      await tester.pumpAndSettle();
      expect(tester.widget<DynoChart>(find.byType(DynoChart)).runs.length, 3);
      expect(encodeSharedState(saved!), before);
      chart.onRpm(7500);
      await tester.pumpAndSettle();
      expect(encodeSharedState(saved!), before);
      await tester.ensureVisible(
        find.byKey(const ValueKey('normalize-weight')),
      );
      await tester.tap(find.byKey(const ValueKey('normalize-weight')));
      await tester.pumpAndSettle();
      expect(saved!['normalizeByWeight'], isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Deleting a comparison reapplies default colors in list order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      DynoLabApp(initialUrlState: encodeSharedState(fixture())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove comparison 1'));
    await tester.pumpAndSettle();
    final chart = tester.widget<DynoChart>(find.byType(DynoChart));
    expect(chart.runs.map((r) => r.color), palette.take(3));
    expect(chart.runs.map((r) => r.config.id), [
      'ktm-stock',
      'honda-stock',
      'ktm-coober',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Library, search, collection, and source interactions do not change the shared URL',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      final state = fixture();
      state['view'] = {
        'panel': 'source',
        'sourceId': 'ktm-coober',
        'category': 'Requested',
        'query': 'ignored',
      };
      await tester.pumpWidget(
        DynoLabApp(
          initialUrlState: encodeSharedState(state),
          onStateChanged: (s) => saved = s,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SourceDialog), findsNothing);
      expect(find.byType(LibraryDialog), findsNothing);
      final before = encodeSharedState(saved!);
      await tester.tap(find.text('Dyno library'));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('library-search'));
      expect(tester.widget<TextField>(search).controller!.text, '');
      await tester.enterText(search, 'CRF300F');
      await tester.pumpAndSettle();
      expect(find.text('SOURCE ONLY'), findsOneWidget);
      expect(encodeSharedState(saved!), before);
      await tester.tap(find.byTooltip('Close library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('About the data'));
      await tester.pumpAndSettle();
      expect(find.byType(SourceDialog), findsOneWidget);
      expect(encodeSharedState(saved!), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Invalid shared links silently retain a usable default comparison',
    (tester) async {
      await tester.pumpWidget(const DynoLabApp(initialUrlState: 'broken'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DynoChart>(find.byType(DynoChart))
            .runs
            .map((r) => r.config.id),
        ['honda-stock', 'ktm-stock'],
      );
      expect(
        find.textContaining('This shared link could not be read'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
