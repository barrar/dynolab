import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'platform/browser.dart' as browser;
import 'dyno_chart.dart';
import 'dyno_data.dart';
import 'value_format.dart';
import 'share_state.dart';
part 'library_dialog.dart';

void main() => runApp(const DynoLabApp());
const paper = Color(0xFFF5F6F2);
const accent = Color(0xFFDF6037);
const palette = [
  Color(0xFF5074DD),
  Color(0xFFE77B3F),
  Color(0xFF26967A),
  Color(0xFF9365BF),
];
const libraryCategories = [
  'All',
  'Adventure',
  'Dual sport',
  '390 upgrades',
  'Requested',
  'Upgrades',
  'More bikes',
];

class DynoLabApp extends StatelessWidget {
  const DynoLabApp({super.key, this.initialUrlState, this.onStateChanged});
  final String? initialUrlState;
  final ValueChanged<Map<String, dynamic>>? onStateChanged;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DynoLab — Motorcycle power, compared',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        surface: Colors.white,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 13),
      ),
      dividerColor: lineColor,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: lineColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 300),
      ),
    ),
    initialRoute: '/',
    home: ComparisonPage(
      initialUrlState: initialUrlState,
      onStateChanged: onStateChanged,
    ),
  );
}

class Selection {
  Selection(
    this.configId, {
    this.visible = true,
    double? weightLb,
    String? weightPresetId,
  }) : weightLb = isValidWeight(weightLb)
           ? weightLb!
           : (weightPresetsFor(
                   configById(configId).bikeId,
                 ).where((p) => p.id == weightPresetId).firstOrNull?.weightLb ??
                 configById(configId).defaultWeight.weightLb) {
    final matching = weightPresetsFor(config.bikeId)
        .where(
          (p) =>
              p.weightLb == this.weightLb &&
              (weightPresetId == null || p.id == weightPresetId),
        )
        .firstOrNull;
    this.weightPresetId = matching?.id ?? 'custom';
  }
  String configId;
  bool visible;
  double weightLb;
  late String weightPresetId;
  WeightPreset? get weightPreset => weightPresetsFor(
    config.bikeId,
  ).where((p) => p.id == weightPresetId).firstOrNull;
  String get weightLabel => weightPreset?.label ?? 'Custom';
  void useWeightPreset(WeightPreset preset) {
    weightPresetId = preset.id;
    weightLb = preset.weightLb;
  }

  Configuration get config => configById(configId);
}

class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key, this.initialUrlState, this.onStateChanged});
  final String? initialUrlState;
  final ValueChanged<Map<String, dynamic>>? onStateChanged;
  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  List<Selection> selections = [
    Selection('honda-stock'),
    Selection('ktm-stock'),
  ];
  Metric metric = Metric.both;
  bool normalizeByWeight = false;
  double rpm = 6000;
  bool includeLoad = false;
  double riderLb = 0, gearLb = 0;
  double get appliedLoadLb => includeLoad ? riderLb + gearLb : 0;
  double totalWeight(Selection selection) => combinedWeight(
    selection.weightLb,
    riderLb: riderLb,
    gearLb: gearLb,
    includeLoad: includeLoad,
  );
  bool get compact => MediaQuery.sizeOf(context).width < 1000;
  Timer? _saveTimer;
  void Function()? _stopUrlListener;
  String panel = 'comparison', libraryCategory = 'All', libraryQuery = '';
  String sourceId = 'honda-stock';
  DialogRoute<void>? _dialogRoute;

  @override
  void initState() {
    super.initState();
    String? encoded;
    try {
      encoded = widget.initialUrlState ?? browser.readUrlState();
    } catch (_) {}
    final shared = decodeSharedState(encoded);
    if (shared != null) {
      _restore(shared);
    } else {
      _loadSaved();
    }
    _stopUrlListener = browser.listenToUrlChanges(_urlChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (panel != 'comparison') _presentPanel(panel, persist: false);
      save();
    });
  }

  void _loadSaved() {
    try {
      final saved = browser.readStorage('dynolab-v1');
      if (saved != null) _restore(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      /* Browser storage is optional. */
    }
  }

  void _restore(Map<String, dynamic> map) {
    final rows = (map['runs'] as List).take(4).toList();
    if (rows.isNotEmpty) {
      selections = rows.map((entry) {
        final row = entry as Map<String, dynamic>;
        return Selection(
          configById(row['id'] as String).id,
          visible: row['visible'] != false,
          weightLb: (row['weightLb'] as num?)?.toDouble(),
          weightPresetId: row['weightPresetId'] as String?,
        );
      }).toList();
    }
    normalizeByWeight =
        map['normalizeByWeight'] == true || map['metric'] == 'powerToWeight';
    metric = Metric.values.firstWhere(
      (m) => m.name == map['metric'],
      orElse: () => Metric.both,
    );
    final savedRider = (map['riderLb'] as num?)?.toDouble();
    final savedGear = (map['gearLb'] as num?)?.toDouble();
    riderLb = isValidLoadWeight(savedRider) ? savedRider! : 0;
    gearLb = isValidLoadWeight(savedGear) ? savedGear! : 0;
    includeLoad = map['includeLoad'] == true;
    final view = map['view'] as Map<String, dynamic>? ?? {};
    panel = ['comparison', 'library', 'source'].contains(view['panel'])
        ? view['panel'] as String
        : 'comparison';
    libraryCategory = libraryCategories.contains(view['category'])
        ? view['category'] as String
        : 'All';
    libraryQuery = view['query'] as String? ?? '';
    sourceId = configurations.any((c) => c.id == view['sourceId'])
        ? view['sourceId'] as String
        : configurations.first.id;
  }

  Map<String, dynamic> snapshot() => {
    'version': sharedStateVersion,
    'metric': metric.name,
    'normalizeByWeight': normalizeByWeight,
    'includeLoad': includeLoad,
    'riderLb': riderLb,
    'gearLb': gearLb,
    'runs': selections
        .map(
          (s) => {
            'id': s.configId,
            'visible': s.visible,
            'weightLb': s.weightLb,
            'weightPresetId': s.weightPresetId,
          },
        )
        .toList(),
    'view': {
      'panel': panel,
      'sourceId': sourceId,
      'category': libraryCategory,
      'query': libraryQuery,
    },
  };

  void _urlChanged() {
    final restored = decodeSharedState(browser.readUrlState());
    if (restored == null) return;
    _saveTimer?.cancel();
    _removePanel();
    setState(() => _restore(restored));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (panel != 'comparison') _presentPanel(panel, persist: false);
      save();
    });
  }

  void save() {
    _saveTimer?.cancel();
    final state = snapshot();
    try {
      browser.writeStorage('dynolab-v1', jsonEncode(state));
    } catch (_) {}
    try {
      browser.writeUrlState(encodeSharedState(state));
    } catch (_) {}
    widget.onStateChanged?.call(state);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) save();
    });
  }

  Future<void> copyLink() async {
    save();
    final url = urlWithSharedState(
      Uri.parse(browser.currentUrl()),
      encodeSharedState(snapshot()),
    ).toString();
    try {
      await browser.copyText(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied. It includes your comparison settings.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Copy this page link'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(child: SelectableText(url)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _stopUrlListener?.call();
    super.dispose();
  }

  void change(VoidCallback fn) {
    setState(fn);
    save();
  }

  void add([String? id, String? weightPresetId]) {
    if (selections.length >= 4) return;
    final next =
        id ??
        (selections.any((s) => s.configId == 'honda-stock')
            ? 'honda-stage1'
            : 'honda-stock');
    if (!configById(next).hasCurve ||
        !isValidWeight(configById(next).defaultWeight.weightLb)) {
      return;
    }
    change(
      () => selections.add(Selection(next, weightPresetId: weightPresetId)),
    );
  }

  void reset() => change(() {
    selections = [Selection('honda-stock'), Selection('ktm-stock')];
    metric = Metric.both;
    normalizeByWeight = false;
    rpm = 6000;
    includeLoad = false;
    riderLb = 0;
    gearLb = 0;
  });
  List<ChartRun> get runs => selections
      .asMap()
      .entries
      .where((e) => e.value.visible)
      .map(
        (e) => ChartRun(
          e.value.config,
          palette[e.key],
          String.fromCharCode(65 + e.key),
          weightLb: e.value.weightLb,
          loadWeightLb: appliedLoadLb,
          weightLabel: e.value.weightLabel,
        ),
      )
      .toList();

  void source([Configuration? configuration]) {
    if (configuration != null && configuration.id != sourceId) {
      sourceId = configuration.id;
    }
    _presentPanel('source');
  }

  void library() => _presentPanel('library');

  void _removePanel() {
    final route = _dialogRoute;
    _dialogRoute = null;
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  void _presentPanel(String next, {bool persist = true}) {
    _removePanel();
    panel = next;
    final route = DialogRoute<void>(
      context: context,
      builder: (context) => next == 'library'
          ? LibraryDialog(
              canAdd: selections.length < 4,
              initialCategory: libraryCategory,
              initialQuery: libraryQuery,
              onViewChanged: (category, query) {
                libraryCategory = category;
                libraryQuery = query;
                _scheduleSave();
              },
              onCopyLink: copyLink,
              onSelect: (id, preset) {
                _removePanel();
                panel = 'comparison';
                add(id, preset);
              },
              onSource: (c) => source(c),
            )
          : SourceDialog(
              initial: configById(sourceId),
              onSelected: (c) {
                sourceId = c.id;
                save();
              },
              onCopyLink: copyLink,
            ),
    );
    _dialogRoute = route;
    if (persist) save();
    Navigator.of(context).push(route).whenComplete(() {
      if (!mounted || _dialogRoute != route) return;
      _dialogRoute = null;
      panel = 'comparison';
      save();
    });
  }

  void preset(String bikeId) => change(() {
    final ids = bikeId == 'honda'
        ? ['honda-stock', 'honda-stage1']
        : ['ktm-stock', 'ktm-coober'];
    selections = ids.map((id) => Selection(id)).toList();
  });
  void export() {
    final lines = <List<String>>[
      ['DynoLab — approximate chart readings, not original dyno runs'],
      for (var i = 0; i < selections.length; i++)
        [
          'Comparison ${String.fromCharCode(65 + i)} source',
          selections[i].config.bike.fullName,
          selections[i].config.name,
          selections[i].config.source.url,
          selections[i].config.measurementBasis,
        ],
      [
        'Power-to-weight method',
        'Per-100-pound values = 100 × horsepower or torque / (bike weight + included rider and gear). Weight presets change mass only, not the source dyno curve.',
      ],
      ['Include rider and gear', '$includeLoad'],
      ['Rider (lb)', formatValue(riderLb)],
      ['Gear and luggage (lb)', formatValue(gearLb)],
      ['Shared load applied per bike (lb)', formatValue(appliedLoadLb)],
      for (var i = 0; i < selections.length; i++)
        [
          'Comparison ${i + 1} weights',
          selections[i].weightLabel,
          'Bike (lb)',
          formatValue(selections[i].weightLb),
          'Total (lb)',
          formatValue(totalWeight(selections[i])),
        ],
      [
        'Method',
        'Recorded torque is averaged with HP-implied torque; interpolate averaged torque and calculate HP from torque and RPM. Values use three significant figures. Blank means outside source range.',
      ],
      [
        'RPM',
        for (final s in selections) ...[
          '${s.config.bike.fullName} / ${s.config.shortName} / hp (approx)',
          '${s.config.bike.fullName} / ${s.config.shortName} / lb-ft (approx)',
          '${s.config.bike.fullName} / ${s.weightLabel} / ${s.config.shortName} / hp/100 lb at ${formatValue(totalWeight(s))} lb total (approx)',
          '${s.config.bike.fullName} / ${s.weightLabel} / ${s.config.shortName} / lb-ft/100 lb at ${formatValue(totalWeight(s))} lb total (approx)',
        ],
      ],
      for (
        var r = DynoChart.minFor(runs);
        r <= DynoChart.maxFor(runs);
        r += 100
      )
        [
          formatValue(r),
          for (final s in selections) ...[
            s.config.at(r) == null ? '' : formatValue(s.config.at(r)!.hp),
            s.config.at(r) == null
                ? ''
                : formatValue(torqueLbFt(s.config.at(r)!.torqueNm)),
            s.config.at(r) == null
                ? ''
                : formatValue(
                    horsepowerPer100Pounds(s.config.at(r)!.hp, totalWeight(s)),
                  ),
            s.config.at(r) == null
                ? ''
                : formatValue(
                    torquePer100Pounds(
                      s.config.at(r)!.torqueNm,
                      totalWeight(s),
                    ),
                  ),
          ],
        ],
    ].map((row) => row.map((v) => '"${v.replaceAll('"', '""')}"').join(',')).toList();
    browser.downloadCsv(lines.join('\r\n'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparison exported as CSV.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 42),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 37),
                      _intro(),
                      const SizedBox(height: 22),
                      _sharedLoadControls(),
                      const SizedBox(height: 20),
                      _selectionCards(),
                      const SizedBox(height: 22),
                      _chartPanel(),
                      const SizedBox(height: 20),
                      _dataNote(),
                      const SizedBox(height: 26),
                      _explore(),
                      const SizedBox(height: 30),
                      _footer(),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Container(
    height: compact ? 72 : 82,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: lineColor)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 42),
          child: Row(
            children: [
              const _Brand(),
              if (!compact) ...[
                const SizedBox(width: 54),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, size: 16),
                      SizedBox(width: 7),
                      Text(
                        'Compare',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: library,
                  child: const Text(
                    'Dyno library',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
              const Spacer(),
              if (!compact) ...[
                const _Dot(color: Color(0xFF67A280), size: 6),
                const SizedBox(width: 7),
                Text(
                  '${bikes.length} bike families · ${configurations.where((c) => c.hasCurve).length} curves',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(width: 24),
              ],
              if (compact)
                SizedBox(
                  width: 36,
                  child: IconButton(
                    key: const ValueKey('copy-page-link'),
                    onPressed: copyLink,
                    tooltip: 'Copy page link',
                    icon: const Icon(Icons.link_rounded, size: 20),
                  ),
                )
              else
                TextButton.icon(
                  key: const ValueKey('copy-page-link'),
                  onPressed: copyLink,
                  icon: const Icon(Icons.link_rounded, size: 17),
                  label: const Text(
                    'Copy link',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              IconButton(
                onPressed: () => source(),
                tooltip: 'About the data',
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: muted,
                  size: 20,
                ),
              ),
              if (compact)
                IconButton(
                  onPressed: library,
                  tooltip: 'Dyno library',
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _intro() => LayoutBuilder(
    builder: (context, box) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 20,
      runSpacing: 20,
      children: [
        SizedBox(
          width: box.maxWidth > 740 ? box.maxWidth - 250 : box.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THE MOTORCYCLE COMPARISON WORKSPACE',
                style: TextStyle(
                  fontSize: 9,
                  color: muted,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Power, put in perspective.',
                style: TextStyle(
                  fontSize: compact ? 28 : 36,
                  letterSpacing: -1.6,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Compare the curves. Explore the upgrades. Find your power band.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: selections.length < 4 ? () => add() : null,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(
            selections.length < 4 ? 'Add comparison' : '4 comparisons added',
          ),
        ),
      ],
    ),
  );

  Widget _sharedLoadControls() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: lineColor),
      borderRadius: BorderRadius.circular(10),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final heading = Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 21, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rider & gear',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    includeLoad
                        ? '${formatValue(appliedLoadLb)} lb added to every bike'
                        : 'Optional shared load for every bike',
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'Include rider and gear for all bikes',
              child: Switch(
                key: const ValueKey('include-load'),
                value: includeLoad,
                onChanged: (value) => change(() {
                  includeLoad = value;
                  if (value) normalizeByWeight = true;
                }),
              ),
            ),
          ],
        );
        final fields = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LoadWeightInput(
                fieldKey: const ValueKey('rider-weight'),
                label: 'Rider',
                valueLb: riderLb,
                enabled: includeLoad,
                onChanged: (v) => change(() => riderLb = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LoadWeightInput(
                fieldKey: const ValueKey('gear-weight'),
                label: 'Gear & luggage',
                valueLb: gearLb,
                enabled: includeLoad,
                onChanged: (v) => change(() => gearLb = v),
              ),
            ),
          ],
        );
        return box.maxWidth < 660
            ? Column(children: [heading, const SizedBox(height: 16), fields])
            : Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 32),
                  SizedBox(width: 300, child: fields),
                ],
              );
      },
    ),
  );

  Widget _weightPresetSelector(Selection selection, int index) => Container(
    padding: const EdgeInsets.fromLTRB(11, 7, 6, 7),
    decoration: BoxDecoration(
      border: Border.all(color: lineColor),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        const Icon(Icons.two_wheeler_outlined, size: 16, color: muted),
        const SizedBox(width: 9),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey('weight-preset-$index'),
              value: selection.weightPresetId,
              isExpanded: true,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: muted,
              ),
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final preset in modelPresetsFor(
                  selection.config.bikeId,
                  selectedId: selection.weightPresetId,
                ))
                  DropdownMenuItem(
                    value: preset.id,
                    child: Text(
                      '${preset.label} · ${formatValue(preset.weightLb)} lb',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom bike weight'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                change(() {
                  if (value == 'custom') {
                    selection.weightPresetId = value;
                  } else {
                    selection.useWeightPreset(
                      weightPresetsFor(
                        selection.config.bikeId,
                      ).firstWhere((p) => p.id == value),
                    );
                  }
                });
              },
            ),
          ),
        ),
        if (selection.weightPreset != null)
          SizedBox(
            width: 30,
            height: 28,
            child: IconButton(
              tooltip:
                  'Weight preset source · ${formatMeasurements(selection.weightPreset!.basis)}',
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 13,
                color: muted,
              ),
              onPressed: () =>
                  browser.openExternal(selection.weightPreset!.sourceUrl),
            ),
          ),
      ],
    ),
  );

  Widget _selectionCards() => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth < 720 ? 1 : 2;
      final width = (box.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (var i = 0; i < selections.length; i++)
            SizedBox(width: width, child: _bikeCard(i)),
        ],
      );
    },
  );
  Widget _bikeCard(int index) {
    final selection = selections[index], config = selection.config;
    final bike = config.bike;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selection.visible ? lineColor : const Color(0xFFD6DAD5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            Container(
              height: 3,
              color: selection.visible ? palette[index] : lineColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 16, 19, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _letter(String.fromCharCode(65 + index), palette[index]),
                      const SizedBox(width: 9),
                      Text(
                        'COMPARISON ${index + 1}',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Show or hide both curves',
                        child: SizedBox(
                          height: 25,
                          width: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => change(
                              () => selection.visible = !selection.visible,
                            ),
                            icon: Icon(
                              selection.visible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 17,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                      if (selections.length > 1)
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: IconButton(
                            tooltip: 'Remove comparison ${index + 1}',
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                change(() => selections.removeAt(index)),
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.two_wheeler_outlined,
                          size: 16,
                          color: muted,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: ValueKey('bike-$index'),
                              value: bike.id,
                              isExpanded: true,
                              isDense: true,
                              icon: const Icon(
                                Icons.unfold_more_rounded,
                                color: muted,
                                size: 16,
                              ),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              items: bikes
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b.id,
                                      enabled: configurations.any(
                                        (c) => c.bikeId == b.id && c.hasCurve,
                                      ),
                                      child: Text(
                                        b.fullName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                if (id != null) {
                                  change(() {
                                    selection.configId = configurations
                                        .firstWhere(
                                          (c) => c.bikeId == id && c.hasCurve,
                                        )
                                        .id;
                                    selection.useWeightPreset(
                                      selection.config.defaultWeight,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${bike.years}  /  ${formatMeasurements(bike.displacement)}',
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ),
                      if (!config.isWheelMeasurement)
                        _tag('BASIS NOT STATED', palette[index])
                      else if (bike.id == 'ktm' && !compact)
                        _tag('PLATFORM REF.', palette[index]),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          config.upgraded
                              ? Icons.bolt_rounded
                              : Icons.tune_rounded,
                          size: 16,
                          color: config.upgraded ? palette[index] : muted,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              key: ValueKey('configuration-$index'),
                              value: config.id,
                              isExpanded: true,
                              isDense: true,
                              icon: const Icon(
                                Icons.unfold_more_rounded,
                                size: 16,
                                color: muted,
                              ),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                              items: configurations
                                  .where(
                                    (c) => c.bikeId == bike.id && c.hasCurve,
                                  )
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                if (id != null) {
                                  change(() => selection.configId = id);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (config.gainSummary.isNotEmpty) ...[
                    Text(
                      formatMeasurements(config.gainSummary),
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.6,
                        color: muted,
                      ),
                    ),
                    if (config.baseline?.hasCurve == true &&
                        selections.length < 4)
                      TextButton.icon(
                        key: ValueKey('add-baseline-$index'),
                        onPressed: () => change(() {
                          selections.add(
                            Selection(
                              config.baseline!.id,
                              weightLb: selection.weightLb,
                              weightPresetId: selection.weightPresetId,
                            ),
                          );
                        }),
                        icon: const Icon(
                          Icons.compare_arrows_rounded,
                          size: 14,
                        ),
                        label: const Text('Add matching stock run'),
                      ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'MODEL / VARIANT WEIGHT',
                    style: TextStyle(
                      fontSize: 8,
                      color: muted,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _weightPresetSelector(selection, index),
                  const SizedBox(height: 5),
                  const Text(
                    'Model changes weight only. Dyno run keeps its tested bike and year.',
                    style: TextStyle(fontSize: 9, color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  BikeWeightField(
                    key: ObjectKey(selection),
                    index: index,
                    weightLb: selection.weightLb,
                    reference:
                        selection.weightPreset?.basis ??
                        'Custom bike weight for this comparison.',
                    onChanged: (weight) => change(() {
                      selection.weightLb = weight;
                      selection.weightPresetId = 'custom';
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatValue(totalWeight(selection))} lb ${includeLoad ? 'total · includes rider & gear' : 'bike only'}',
                    key: ValueKey('total-weight-$index'),
                    style: const TextStyle(fontSize: 9, color: muted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _peak(
                          normalizeByWeight
                              ? formatValue(
                                  horsepowerPer100Pounds(
                                    config.peakHp,
                                    totalWeight(selection),
                                  ),
                                )
                              : formatValue(config.peakHp),
                          normalizeByWeight ? 'hp/100 lb' : 'hp',
                          normalizeByWeight
                              ? 'PEAK HP / 100 LB ≈'
                              : 'PEAK POWER ≈',
                          palette[index],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 33,
                        color: lineColor,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(
                        child: _peak(
                          normalizeByWeight
                              ? formatValue(
                                  torquePer100Pounds(
                                    config.peakNm,
                                    totalWeight(selection),
                                  ),
                                )
                              : formatValue(torqueLbFt(config.peakNm)),
                          normalizeByWeight ? 'lb-ft/100 lb' : 'lb-ft',
                          normalizeByWeight
                              ? 'PEAK TORQUE / 100 LB ≈'
                              : 'PEAK TORQUE ≈',
                          palette[index],
                        ),
                      ),
                      TextButton(
                        onPressed: () => source(config),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              compact ? 'Details' : 'Build details',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.north_east_rounded,
                              size: 12,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _peak(String value, String suffix, String title, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontFamily: 'Manrope'),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: ' $suffix',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _chartPanel() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: lineColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 25,
            22,
            compact ? 16 : 25,
            14,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 20,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The power comparison',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _lineLegend(
                        normalizeByWeight
                            ? 'Horsepower / 100 lb'
                            : 'Horsepower',
                        false,
                      ),
                      _lineLegend(
                        normalizeByWeight ? 'Torque / 100 lb' : 'Torque',
                        true,
                      ),
                      const Text(
                        'Chart-derived ≈',
                        style: TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: paper,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in Metric.values) _metricButton(item),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Per 100 lb',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Switch(
                        key: const ValueKey('normalize-weight'),
                        value: normalizeByWeight,
                        onChanged: (value) =>
                            change(() => normalizeByWeight = value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (normalizeByWeight)
          Padding(
            padding: EdgeInsets.fromLTRB(25, 0, 25, 16),
            child: Text(
              'Per-100-pound view: 100 × horsepower and torque ÷ ${includeLoad ? 'total weight (bike + rider + gear)' : 'bike weight'}. Model weight presets do not change the source dyno curve.',
              style: TextStyle(fontSize: 10, color: muted, height: 1.6),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 19),
          child: SizedBox(
            height: compact ? 345 : 390,
            child: runs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_off_outlined,
                          size: 30,
                          color: muted,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'All comparisons are hidden.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => change(() {
                            for (final s in selections) {
                              s.visible = true;
                            }
                          }),
                          child: const Text('Show curves'),
                        ),
                      ],
                    ),
                  )
                : DynoChart(
                    key: const ValueKey('dyno-chart'),
                    runs: runs,
                    rpm: rpm,
                    onRpm: (value) => setState(() => rpm = value),
                    metric: metric,
                    normalizeByWeight: normalizeByWeight,
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 8, 25, 19),
          child: Row(
            children: [
              const Icon(Icons.ads_click_rounded, size: 13, color: muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  compact
                      ? 'Touch or drag to inspect. Cursor stays at your last position.'
                      : 'Hover to inspect · Touch and drag on mobile · Arrow keys move the cursor',
                  style: const TextStyle(color: muted, fontSize: 9),
                ),
              ),
              if (!compact) ...[
                const _Dot(color: Color(0xFF67A280), size: 5),
                const SizedBox(width: 5),
                const Text(
                  'LAST POSITION HELD',
                  style: TextStyle(
                    color: muted,
                    fontSize: 8,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 25,
            vertical: 18,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFBF8),
            border: Border(top: BorderSide(color: lineColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AT ${formatRpm(rpm)} RPM',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'INTERPOLATED VALUES ≈',
                    style: TextStyle(
                      color: muted,
                      fontSize: 8,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth < 620
                      ? 1
                      : mathColumns(runs.length);
                  return Wrap(
                    spacing: 20,
                    runSpacing: 15,
                    children: [
                      for (final run in runs)
                        SizedBox(
                          width: (box.maxWidth - (cols - 1) * 20) / cols,
                          child: _readout(run),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: reset,
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  size: 14,
                  color: muted,
                ),
                label: const Text(
                  'Reset comparison',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: export,
                icon: const Icon(
                  Icons.file_download_outlined,
                  size: 15,
                  color: ink,
                ),
                label: const Text(
                  'Export CSV',
                  style: TextStyle(
                    color: ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  int mathColumns(int n) => n < 2 ? 1 : 2;
  Widget _metricButton(Metric item) => InkWell(
    borderRadius: BorderRadius.circular(5),
    onTap: () => change(() => metric = item),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: metric == item ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        boxShadow: metric == item
            ? [
                BoxShadow(
                  color: ink.withValues(alpha: .05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        item == Metric.both
            ? 'Both'
            : item == Metric.power
            ? 'Power'
            : 'Torque',
        style: TextStyle(
          color: metric == item ? ink : muted,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    ),
  );
  Widget _readout(ChartRun run) {
    final p = run.config.at(rpm);
    final values = <Widget>[
      if (p == null)
        const Text(
          'No data at this RPM',
          style: TextStyle(fontSize: 9, color: muted),
        )
      else ...[
        _value(
          normalizeByWeight
              ? formatValue(horsepowerPer100Pounds(p.hp, run.totalWeightLb))
              : formatValue(p.hp),
          normalizeByWeight ? 'hp/100 lb' : 'hp',
          run.color,
        ),
        _value(
          normalizeByWeight
              ? formatValue(torquePer100Pounds(p.torqueNm, run.totalWeightLb))
              : formatValue(torqueLbFt(p.torqueNm)),
          normalizeByWeight ? 'lb-ft/100 lb' : 'lb-ft',
          run.color,
        ),
      ],
    ];
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          run.config.bike.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          '${run.weightLabel} · ${run.config.shortName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: muted),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 440
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _letter(run.letter, run.color),
                    const SizedBox(width: 9),
                    Expanded(child: name),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 18, runSpacing: 5, children: values),
              ],
            )
          : Row(
              children: [
                _letter(run.letter, run.color),
                const SizedBox(width: 9),
                Expanded(child: name),
                Wrap(spacing: 18, children: values),
              ],
            ),
    );
  }

  Widget _value(String text, String suffix, Color color) => RichText(
    text: TextSpan(
      style: const TextStyle(fontFamily: 'Manrope'),
      children: [
        TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(
          text: ' $suffix',
          style: const TextStyle(color: muted, fontSize: 9),
        ),
      ],
    ),
  );
  Widget _lineLegend(String title, bool dashed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 22,
        child: Row(
          children: [
            for (var i = 0; i < (dashed ? 3 : 1); i++)
              Container(
                width: dashed ? 4 : 19,
                height: 2,
                margin: EdgeInsets.only(right: dashed ? 3 : 0),
                color: ink.withValues(alpha: dashed ? .5 : .9),
              ),
          ],
        ),
      ),
      const SizedBox(width: 5),
      Text(title, style: const TextStyle(fontSize: 9, color: muted)),
    ],
  );
  Widget _dataNote() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0E9),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: muted, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            selections.any((s) => !s.config.isWheelMeasurement)
                ? 'Check measurement basis. One or more selected runs do not state rear-wheel measurement. Engine/crank estimates and wheel dyno figures are not directly comparable; inspect build details.'
                : selections.any((s) => s.config.bikeId == 'ktm')
                ? 'A little context matters. Curves are approximate chart readings. KTM uses a 390 Euro 5b platform reference; the tested body model is unspecified. Different dynos and conditions affect the comparison.'
                : 'A little context matters. Curves are approximate readings from published dyno charts, with interpolation between samples. Peak figures and source hardware are available in build details.',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6D766D),
              height: 1.7,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 18),
          TextButton(
            onPressed: () => source(),
            child: const Text(
              'Read the source notes ↗',
              style: TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _explore() => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'TRY A COMPARISON',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1,
            color: muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => preset('honda'),
          icon: const Icon(Icons.bolt_rounded, size: 14),
          label: const Text('CRF300L: stock vs. Stage 1.0'),
        ),
        OutlinedButton.icon(
          onPressed: () => preset('ktm'),
          icon: const Icon(Icons.bolt_rounded, size: 14),
          label: const Text('390: stock vs. COOBER'),
        ),
      ],
    ),
  );
  Widget _footer() => Row(
    children: [
      const Text(
        'DYNO',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: -.5,
        ),
      ),
      const Text(
        ' / LAB',
        style: TextStyle(
          color: muted,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      const SizedBox(width: 14),
      const Expanded(
        child: Text(
          'Built for the curious rider.',
          style: TextStyle(color: muted, fontSize: 9),
        ),
      ),
      TextButton(
        onPressed: () => source(),
        child: const Text(
          'Sources & methodology',
          style: TextStyle(fontSize: 9, color: muted),
        ),
      ),
    ],
  );
}

Widget _letter(String letter, Color color) => Container(
  width: 25,
  height: 25,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: color.withValues(alpha: .1),
    borderRadius: BorderRadius.circular(5),
  ),
  child: Text(
    letter,
    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
  ),
);
Widget _tag(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .08),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 7,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: .4,
    ),
  ),
);

class LoadWeightInput extends StatefulWidget {
  const LoadWeightInput({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.valueLb,
    required this.enabled,
    required this.onChanged,
  });
  final Key fieldKey;
  final String label;
  final double valueLb;
  final bool enabled;
  final ValueChanged<double> onChanged;
  @override
  State<LoadWeightInput> createState() => _LoadWeightInputState();
}

class _LoadWeightInputState extends State<LoadWeightInput> {
  late final controller = TextEditingController(
    text: widget.valueLb.toStringAsFixed(0),
  );
  bool invalid = false;
  late final FocusNode focusNode = FocusNode()
    ..addListener(() {
      if (!focusNode.hasFocus && !invalid) {
        controller.text = widget.valueLb.toStringAsFixed(0);
      }
    });
  @override
  void didUpdateWidget(covariant LoadWeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.enabled && oldWidget.enabled) ||
        (oldWidget.valueLb != widget.valueLb && !focusNode.hasFocus)) {
      controller.text = widget.valueLb.toStringAsFixed(0);
      invalid = false;
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: widget.fieldKey,
    controller: controller,
    focusNode: focusNode,
    enabled: widget.enabled,
    keyboardType: TextInputType.number,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    decoration: InputDecoration(
      labelText: widget.label,
      suffixText: 'lb',
      isDense: true,
      labelStyle: const TextStyle(fontSize: 10),
      errorText: invalid ? 'Use zero or a positive weight' : null,
      errorMaxLines: 2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: lineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: lineColor),
      ),
    ),
    onChanged: (text) {
      final value = double.tryParse(text.trim());
      final valid =
          RegExp(r'^\d*\.?\d*$').hasMatch(text.trim()) &&
          isValidLoadWeight(value);
      setState(() => invalid = !valid);
      if (valid) widget.onChanged(value!.roundToDouble());
    },
  );
}

class BikeWeightField extends StatefulWidget {
  const BikeWeightField({
    super.key,
    required this.index,
    required this.weightLb,
    required this.reference,
    required this.onChanged,
  });
  final int index;
  final double weightLb;
  final String reference;
  final ValueChanged<double> onChanged;
  @override
  State<BikeWeightField> createState() => _BikeWeightFieldState();
}

class _BikeWeightFieldState extends State<BikeWeightField> {
  late final TextEditingController controller = TextEditingController(
    text: _text(widget.weightLb),
  );
  String? error;
  late final FocusNode focusNode = FocusNode()
    ..addListener(() {
      if (!focusNode.hasFocus && error == null) {
        controller.text = _text(widget.weightLb);
      }
    });
  String _text(double weight) => formatValue(weight);
  @override
  void didUpdateWidget(covariant BikeWeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightLb != widget.weightLb &&
        double.tryParse(controller.text) != widget.weightLb) {
      controller.text = _text(widget.weightLb);
      error = null;
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.scale_outlined, size: 15, color: muted),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'Bike weight',
              style: TextStyle(fontSize: 10, color: muted),
            ),
          ),
          Tooltip(
            message:
                '${formatMeasurements(widget.reference)} Reference weights exclude rider and luggage. Edit for your actual build.',
            child: const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: muted,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 106,
            child: Semantics(
              label: 'Bike weight for comparison ${widget.index + 1} in pounds',
              child: TextField(
                key: ValueKey('weight-${widget.index}'),
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: 'lb',
                  hintText: 'Weight',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: lineColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: error == null ? lineColor : Colors.red,
                    ),
                  ),
                ),
                onChanged: (text) {
                  final value = double.tryParse(text.trim());
                  final valid =
                      RegExp(r'^\d*\.?\d*$').hasMatch(text.trim()) &&
                      isValidWeight(value);
                  setState(
                    () => error = valid
                        ? null
                        : 'Enter a positive weight in pounds. The chart keeps the last valid weight.',
                  );
                  if (valid) widget.onChanged(value!);
                },
              ),
            ),
          ),
        ],
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            error!,
            style: const TextStyle(fontSize: 9, color: Colors.red, height: 1.5),
          ),
        ),
    ],
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(
          Icons.multiline_chart_rounded,
          color: Color(0xFFF59664),
          size: 21,
        ),
      ),
      const SizedBox(width: 9),
      const Text(
        'DYNO',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -.8,
        ),
      ),
      const Text(
        ' / LAB',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 18,
          letterSpacing: -.8,
        ),
      ),
    ],
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class SourceDialog extends StatefulWidget {
  const SourceDialog({
    super.key,
    this.initial,
    this.onSelected,
    this.onCopyLink,
  });
  final Configuration? initial;
  final ValueChanged<Configuration>? onSelected;
  final VoidCallback? onCopyLink;
  @override
  State<SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<SourceDialog> {
  late Configuration selected = widget.initial ?? configurations.first;
  void open(String url) => browser.openExternal(url);
  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850, maxHeight: 850),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Behind the curves',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                ),
                if (widget.onCopyLink != null)
                  IconButton(
                    key: const ValueKey('copy-source-link'),
                    onPressed: widget.onCopyLink,
                    tooltip: 'Copy page link',
                    icon: const Icon(Icons.link_rounded),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close source details',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Source charts, fitted parts, and the limits of the data.',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      key: ValueKey('source-configuration-${selected.id}'),
                      initialValue: selected.id,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Configuration',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontFamily: 'Manrope',
                      ),
                      items: configurations
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                '${c.bike.fullName} · ${c.shortName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id != null) {
                          setState(() => selected = configById(id));
                          widget.onSelected?.call(selected);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _section('REFERENCE BIKE WEIGHT'),
                    const SizedBox(height: 9),
                    Text(
                      weightPresetsFor(selected.bikeId)
                          .map(
                            (p) => p.weightLb > 0
                                ? '${p.label}: ${formatValue(p.weightLb)} lb. ${formatMeasurements(p.basis)}'
                                : '${p.label}: weight not verified. ${p.basis}',
                          )
                          .join('\n'),
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a model weight preset or enter a custom bike weight for each comparison. Presets include fuel and fluids, and exclude rider and luggage. Optional rider and gear weights are shared across every comparison. The Per 100 lb switch scales both horsepower and torque using that total weight.',
                      style: TextStyle(fontSize: 10, color: muted, height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    _section('THE BUILD'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selected.parts
                          .map((p) => _tag(p, accent))
                          .toList(),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      formatMeasurements(selected.notes),
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                    if (selected.gainSummary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _section('PUBLISHED BEFORE / AFTER'),
                      const SizedBox(height: 8),
                      Text(
                        formatMeasurements(selected.gainSummary),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.7,
                        ),
                      ),
                      if (selected.baseline != null)
                        TextButton(
                          onPressed: () {
                            setState(() => selected = selected.baseline!);
                            widget.onSelected?.call(selected);
                          },
                          child: const Text('Inspect this test’s baseline'),
                        ),
                    ],
                    const SizedBox(height: 16),
                    _section('TUNE RESEARCH · NOVEMBER 3, 2026'),
                    const SizedBox(height: 8),
                    Text(
                      tuneResearch[selected.bikeId] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.7,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section('PUBLISHER-REPORTED PEAKS'),
                    const SizedBox(height: 9),
                    Text(
                      formatMeasurements(selected.reportedPeaks),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Publisher figures and any explicitly labeled chart readings are kept separate from the approximate graph samples.',
                      style: TextStyle(fontSize: 10, color: muted, height: 1.7),
                    ),
                    const SizedBox(height: 20),
                    if (!selected.hasCurve)
                      const Text(
                        'Source-only record · no digitized RPM curve available',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    _section('HOW THE CURVES WERE PREPARED'),
                    const SizedBox(height: 9),
                    Text(
                      formatMeasurements(selected.source.method),
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                    if (selected.hasCurve) ...[
                      const SizedBox(height: 14),
                      _section('TORQUE & HORSEPOWER CONSISTENCY'),
                      const SizedBox(height: 9),
                      const Text(
                        'Recorded torque is averaged with the torque implied by recorded horsepower and RPM. The graph interpolates that averaged torque and calculates horsepower from torque and RPM at every position. Measurements display three significant figures; calculations keep full precision. Original source samples are preserved.',
                        style: TextStyle(fontSize: 11, height: 1.8),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Maximum source-point torque adjustment: ${formatValue(selected.recordedPoints.map((p) => TorqueReconciliation(p).torqueChangePercent.abs()).reduce((a, b) => a > b ? a : b))}%. Maximum source-point horsepower adjustment: ${formatValue(selected.recordedPoints.map((p) => TorqueReconciliation(p).hpChangePercent.abs()).reduce((a, b) => a > b ? a : b))}%. No changes exceed the 5.00% review limit.',
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.8,
                          color: muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formatMeasurements(selected.source.caveat),
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.8,
                          color: Color(0xFF8A643F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section('ORIGINAL PUBLISHED CHART'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: lineColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selected.source.asset.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'No public RPM chart is bundled for this record. Open the publisher source below. Peak figures alone are not plotted as a curve.',
                              ),
                            )
                          : Image.asset(
                              selected.source.asset,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              semanticLabel:
                                  'Published ${selected.source.publisher} stock and upgraded dyno chart',
                            ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => open(selected.source.url),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(selected.source.publisher),
                        ),
                        OutlinedButton(
                          onPressed: selected.source.imageUrl.isEmpty
                              ? null
                              : () => open(selected.source.imageUrl),
                          child: const Text('Open original chart'),
                        ),
                        OutlinedButton(
                          onPressed: () => open(selected.bike.weightSourceUrl),
                          child: const Text('Weight reference'),
                        ),
                        if (selected.bikeId == 'honda')
                          OutlinedButton(
                            onPressed: () => open(
                              'https://cdn.shopify.com/s/files/1/0602/0153/3687/files/TuneMatrix_R260625.png?v=1782409419',
                            ),
                            child: const Text('550 hardware matrix'),
                          ),
                        if (selected.bikeId == 'ktm')
                          OutlinedButton(
                            onPressed: () => open(
                              'https://www.coober.eu/product/ktm-390-adv-eur5b-decat-kit/',
                            ),
                            child: const Text('Adventure R kit fitment'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'MODEL & MEASUREMENT NOTES',
                      style: TextStyle(
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Honda CRF300L includes Standard, ABS and Rally weight presets. KTM 390 covers 2025+ Adventure R and Enduro R weight presets. These are weight scenarios using the cited dyno curves, not separate verified dyno tests for each body model. '
                      'Each record identifies its measurement basis and source limitations; engine/crank estimates are not directly comparable with wheel dyno figures. Torque is shown in pound-feet (lb-ft). '
                      'Curves end at the sampled range and are never extrapolated. '
                      'Sources reviewed November 2, 2026.',
                      style: TextStyle(fontSize: 11, color: muted, height: 1.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _section(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      color: muted,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}
