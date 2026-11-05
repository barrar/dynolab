import 'dart:math' as math;
part 'researched_data.dart';

const nmPerLbFt = 1.3558179483;
const hpRpmPerNm = 7120.9092;

bool isValidWeight(double? weightLb) =>
    weightLb != null && weightLb.isFinite && weightLb > 0;

double horsepowerPerPound(double hp, double weightLb) {
  if (!isValidWeight(weightLb)) {
    throw ArgumentError.value(
      weightLb,
      'weightLb',
      'Must be positive and finite',
    );
  }
  return hp / weightLb;
}

double torqueLbFt(double torqueNm) => torqueNm / nmPerLbFt;
double torquePerPound(double torqueNm, double weightLb) =>
    horsepowerPerPound(torqueLbFt(torqueNm), weightLb);

double horsepowerPer100Pounds(double hp, double weightLb) =>
    100 * horsepowerPerPound(hp, weightLb);
double torquePer100Pounds(double torqueNm, double weightLb) =>
    100 * torquePerPound(torqueNm, weightLb);

double horsepowerFromTorque(double torqueNm, double rpm) =>
    torqueNm * rpm / hpRpmPerNm;
double torqueFromHorsepower(double hp, double rpm) {
  if (!rpm.isFinite || rpm <= 0) throw ArgumentError.value(rpm, 'rpm');
  return hp * hpRpmPerNm / rpm;
}

class TorqueReconciliation {
  TorqueReconciliation(this.recorded)
    : impliedTorqueNm = torqueFromHorsepower(recorded.hp, recorded.rpm);
  final DynoPoint recorded;
  final double impliedTorqueNm;
  double get averagedTorqueNm => (recorded.torqueNm + impliedTorqueNm) / 2;
  double get calculatedHp =>
      horsepowerFromTorque(averagedTorqueNm, recorded.rpm);
  double _percent(double before, double after) => before == 0
      ? (after == 0 ? 0 : double.infinity)
      : (after - before) / before * 100;
  double get torqueDiscrepancyPercent =>
      _percent(recorded.torqueNm, impliedTorqueNm);
  double get torqueChangePercent =>
      _percent(recorded.torqueNm, averagedTorqueNm);
  double get hpChangePercent => _percent(recorded.hp, calculatedHp);
  bool get requiresReview =>
      torqueDiscrepancyPercent.abs() > 5 ||
      torqueChangePercent.abs() > 5 ||
      hpChangePercent.abs() > 5;
  DynoPoint apply() {
    if (requiresReview) {
      throw StateError(
        'Torque reconciliation exceeds the user’s 5% review limit at ${recorded.rpm} RPM. Report and obtain approval before applying.',
      );
    }
    return DynoPoint(recorded.rpm, calculatedHp, averagedTorqueNm);
  }
}

class DynoPoint {
  const DynoPoint(this.rpm, this.hp, this.torqueNm);
  final double rpm;
  final double hp;
  final double torqueNm;
}

class DynoSource {
  const DynoSource({
    required this.publisher,
    required this.url,
    required this.imageUrl,
    required this.asset,
    required this.method,
    required this.caveat,
  });
  final String publisher, url, imageUrl, asset, method, caveat;
}

class WeightPreset {
  const WeightPreset(
    this.id,
    this.bikeId,
    this.label,
    this.weightLb,
    this.basis,
    this.sourceUrl,
  );
  final String id, bikeId, label, basis, sourceUrl;
  final double weightLb;
}

const hondaWeightSource =
    'https://powersports.honda.com/-/media/products/family/crf300l-crf250l/brochure/2021/2021-crf300l-brochure.pdf';
const ktmAdventureWeightSource =
    'https://www.ktm.com/en-qa/models/travel/2025-ktm-390-adventurer/technical-specifications.html';
const ktmEnduroWeightSource =
    'https://www.ktm.com/en-us/models/dual-sport/2025-ktm-390-enduror/technical-specifications.html';
final weightPresets = <WeightPreset>[
  WeightPreset(
    'honda-standard',
    'honda',
    'Standard',
    309,
    '2021 Honda CRF300L, non-ABS: 309 lb curb weight, including fluids and full fuel.',
    hondaWeightSource,
  ),
  WeightPreset(
    'honda-abs',
    'honda',
    'Standard ABS',
    311,
    '2021 Honda CRF300L ABS: 311 lb curb weight, including fluids and full fuel.',
    hondaWeightSource,
  ),
  WeightPreset(
    'honda-rally',
    'honda',
    'Rally',
    333,
    '2021 Honda CRF300L Rally, non-ABS: 333 lb curb weight, including fluids and full fuel.',
    hondaWeightSource,
  ),
  WeightPreset(
    'honda-rally-abs',
    'honda',
    'Rally ABS',
    337,
    '2021 Honda CRF300L Rally ABS: 337 lb curb weight, including fluids and full fuel.',
    hondaWeightSource,
  ),
  WeightPreset(
    'ktm-adventure',
    'ktm',
    'Adventure R',
    388,
    '2025 KTM 390 Adventure R: 176 kg fully fueled, approximately 388 lb.',
    ktmAdventureWeightSource,
  ),
  WeightPreset(
    'ktm-enduro',
    'ktm',
    'Enduro R',
    363.8,
    '2025 KTM 390 Enduro R: 165 kg fully fueled, approximately 363.8 lb.',
    ktmEnduroWeightSource,
  ),
  ...researchedWeights,
];
List<WeightPreset> weightPresetsFor(String bikeId) =>
    weightPresets.where((p) => p.bikeId == bikeId).toList();

// Keep historical preset IDs valid for shared links while presenting each
// model/weight combination once. Include the active legacy ID when restored.
List<WeightPreset> modelPresetsFor(String bikeId, {String? selectedId}) {
  final result = <WeightPreset>[];
  for (final preset in weightPresetsFor(bikeId)) {
    final index = result.indexWhere(
      (p) => p.label == preset.label && p.weightLb == preset.weightLb,
    );
    if (index < 0) {
      result.add(preset);
    } else if (preset.id == selectedId) {
      result[index] = preset;
    }
  }
  return result;
}

class Bike {
  const Bike(this.id, this.make, this.name, this.years, this.displacement);
  final String id, make, name, years, displacement;
  WeightPreset get referenceWeight => weightPresetsFor(id).first;
  double get referenceWeightLb => referenceWeight.weightLb;
  String get weightBasis => referenceWeight.basis;
  String get weightSourceUrl => referenceWeight.sourceUrl;
  String get fullName => '$make $name';
}

final bikes = <Bike>[
  Bike('honda', 'Honda', 'CRF300L', '2021+', '286 cc'),
  Bike('ktm', 'KTM', '390', '2025+', '399 cc'),
  ...researchedBikes,
]..sort((a, b) => a.fullName.compareTo(b.fullName));

bool isValidLoadWeight(double? weightLb) =>
    weightLb != null && weightLb.isFinite && weightLb >= 0;

double combinedWeight(
  double bikeLb, {
  double riderLb = 0,
  double gearLb = 0,
  bool includeLoad = false,
}) {
  if (!isValidWeight(bikeLb) ||
      !isValidLoadWeight(riderLb) ||
      !isValidLoadWeight(gearLb)) {
    throw ArgumentError(
      'Bike weight must be positive; rider and gear weights must be nonnegative and finite.',
    );
  }
  return bikeLb + (includeLoad ? riderLb + gearLb : 0);
}

const hondaSource = DynoSource(
  publisher: '550 Performance',
  url:
      'https://www.550performance.com/products/my21-ecu-tuning-honda-crf-300-l',
  imageUrl:
      'https://cdn.shopify.com/s/files/1/0602/0153/3687/files/550Performance_CRF300L_Stage1.0_DynoChart.png?v=1765738829',
  asset: 'assets/charts/honda-550-stage1.png',
  method:
      'Approximate readings digitized from the published stock / 91 AKI Stage 1.0 chart. Between samples, values are linearly interpolated. No original dyno run file was available.',
  caveat:
      'CRF300L rear-wheel dyno results from 550 Performance. The plotted samples are approximate; the printed peak figures are listed separately. Results from different dynos are indicative, not a controlled head-to-head test.',
);

const ktmSource = DynoSource(
  publisher: 'COOBER / Slavens Racing',
  url: 'https://slavensracing.com/shop/ktm-390-cat-delete-kit-by-coober/',
  imageUrl:
      'https://slavensracing.com/wp-content/uploads/2026/03/Coober-390-Cat-Delete-Dyno.png',
  asset: 'assets/charts/ktm-coober-dyno.png',
  method:
      'Torque is approximately digitized from the dotted N·m traces. Horsepower is calculated as torque (N·m) × RPM ÷ 7120.9092. The chart’s solid power traces disagree with its printed peak figures, so they are not used as numerical input.',
  caveat:
      'Platform proxy: the chart identifies KTM 390 Euro 5b, without specifying Adventure R, Duke, or Enduro body model. The seller lists the kit for the 2025–2026 Adventure R, but this is not a verified Adventure R-specific test. The header maxima also differ from the plotted power scale. Use these curves as an approximate platform comparison.',
);

class Configuration {
  Configuration({
    required this.id,
    required this.bikeId,
    required this.name,
    required this.shortName,
    required this.parts,
    required List<DynoPoint> points,
    required this.source,
    required this.reportedPeaks,
    required this.notes,
    this.upgraded = false,
    this.category = 'Original',
    this.selectionReason = '',
    this.usSourceUrl = '',
    this.measurementBasis = 'Rear wheel',
    this.defaultWeightPresetId,
    this.baselineConfigId = '',
    this.gainSummary = '',
  }) : recordedPoints = List.unmodifiable(points);
  final String id, bikeId, name, shortName, reportedPeaks, notes;
  final String category, selectionReason, usSourceUrl, measurementBasis;
  final String baselineConfigId, gainSummary;
  Configuration? get baseline => baselineConfigId.isEmpty
      ? null
      : configurations.where((c) => c.id == baselineConfigId).firstOrNull;
  final String? defaultWeightPresetId;
  WeightPreset get defaultWeight =>
      weightPresetsFor(
        bikeId,
      ).where((p) => p.id == defaultWeightPresetId).firstOrNull ??
      bike.referenceWeight;
  final List<String> parts;
  final List<DynoPoint> recordedPoints;
  late final List<DynoPoint> points = List.unmodifiable(
    recordedPoints.map((p) => TorqueReconciliation(p).apply()),
  );
  final DynoSource source;
  final bool upgraded;
  Bike get bike => bikes.firstWhere((b) => b.id == bikeId);
  bool get hasCurve => points.length >= 2;
  bool get isWheelMeasurement =>
      measurementBasis.toLowerCase().contains('rear wheel') ||
      measurementBasis.toLowerCase().contains('chassis dyno');
  double get minRpm => hasCurve ? points.first.rpm : 0;
  double get maxRpm => hasCurve ? points.last.rpm : 0;
  double get peakHp {
    var peak = points.fold(0.0, (v, p) => math.max(v, p.hp));
    // A linear torque segment produces a quadratic horsepower segment.
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final slope = (b.torqueNm - a.torqueNm) / (b.rpm - a.rpm);
      if (slope >= 0) continue;
      final intercept = a.torqueNm - slope * a.rpm;
      final candidate = -intercept / (2 * slope);
      if (candidate > a.rpm && candidate < b.rpm) {
        peak = math.max(
          peak,
          horsepowerFromTorque(slope * candidate + intercept, candidate),
        );
      }
    }
    return peak;
  }

  double get peakNm => points.fold(0, (v, p) => math.max(v, p.torqueNm));

  // Deliberately no extrapolation: a curve ends where its source data ends.
  DynoPoint? at(double rpm) {
    if (!hasCurve || rpm < minRpm || rpm > maxRpm) return null;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if (rpm <= b.rpm) {
        final t = (rpm - a.rpm) / (b.rpm - a.rpm);
        final torque = a.torqueNm + (b.torqueNm - a.torqueNm) * t;
        return DynoPoint(rpm, horsepowerFromTorque(torque, rpm), torque);
      }
    }
    return points.last;
  }
}

// Source samples: RPM, stock hp, stock lb-ft, Stage 1 hp, Stage 1 lb-ft.
const _hondaSamples = <List<double>>[
  [2500, 6.1, 12.8, 7.3, 15.3],
  [3000, 8.5, 15, 8.7, 15.3],
  [3500, 9.7, 14.6, 10.8, 16.2],
  [4000, 10.9, 14.4, 12.6, 16.6],
  [4500, 12.3, 14.4, 14.2, 16.7],
  [5000, 14.9, 15.7, 17.4, 18.2],
  [5252, 16.55, 16.55, 19.06, 19.06],
  [5500, 17.5, 16.8, 20.5, 19.6],
  [6000, 20.1, 17.6, 22.8, 20.1],
  [6500, 22, 17.9, 24.7, 20],
  [7000, 22.6, 17, 26.4, 19.8],
  [7500, 23, 16.1, 27.4, 19.2],
  [8000, 23.3, 15.3, 27.8, 18.3],
  [8500, 23.3, 14.4, 27.4, 16.9],
  [9000, 21.8, 12.8, 26.8, 15.7],
  [9500, 18.9, 10.4, 25.9, 14.3],
  [10000, 15.6, 8.2, 24.3, 12.7],
  [10400, 13, 6.5, 22.5, 11.4],
];

List<DynoPoint> _honda(bool upgraded) => _hondaSamples
    .map(
      (s) =>
          DynoPoint(s[0], s[upgraded ? 3 : 1], s[upgraded ? 4 : 2] * nmPerLbFt),
    )
    .toList();

// Approximate chart torque samples. The platform and scale caveats above apply.
const _ktmSamples = <List<double>>[
  [3000, 21.5, 27.5],
  [3500, 23.9, 28.7],
  [4000, 23.4, 28.2],
  [4500, 24.2, 27.1],
  [5000, 27.7, 30.0],
  [5500, 29.1, 32.0],
  [6000, 31.4, 34.5],
  [6284, 33.6, 36.23],
  [6461, 34.87, 35.8],
  [6500, 34.8, 35.7],
  [7000, 32.8, 34.1],
  [7500, 31.6, 33.4],
  [8000, 31.8, 33.6],
  [8500, 30.6, 32.6],
  [9000, 28.1, 30.0],
  [9500, 26.7, 29.3],
  [9648, 26.5, 29.0],
  [9800, 26.1, 28.5],
];
List<DynoPoint> _ktm(bool upgraded) => _ktmSamples.map((s) {
  final nm = s[upgraded ? 2 : 1];
  return DynoPoint(s[0], nm * s[0] / hpRpmPerNm, nm);
}).toList();

final configurations = <Configuration>[
  Configuration(
    id: 'honda-stock',
    bikeId: 'honda',
    name: 'Stock',
    shortName: 'Stock',
    parts: ['Factory ECU', 'Stock exhaust', 'Stock intake'],
    points: _honda(false),
    source: hondaSource,
    reportedPeaks: '23.51 hp @ 8,243 RPM · 17.90 lb-ft @ 6,315 RPM',
    notes:
        'Stock baseline from the same published chart as the Stage 1.0 upgrade.',
  ),
  Configuration(
    id: 'honda-stage1',
    bikeId: 'honda',
    name: '550 Performance · Stage 1.0',
    shortName: '550 Stage 1.0',
    upgraded: true,
    baselineConfigId: 'honda-stock',
    gainSummary:
        '23.51 → 27.87 whp (+4.36 hp), publisher Stage 1.0 comparison.',
    parts: [
      '91 AKI Stage 1.0 ECU',
      'Full performance exhaust',
      'High-flow airbox lid',
      'High-flow velocity stack',
    ],
    points: _honda(true),
    source: hondaSource,
    reportedPeaks: '27.87 hp @ 7,961 RPM · 20.08 lb-ft @ 6,305 RPM',
    notes:
        '91 AKI tune requires matching hardware. 550’s tune matrix specifies a full performance exhaust, high-flow airbox lid and velocity stack. A stock air filter is permitted; an aftermarket filter and high-flow snorkel are recommended. This is not the stock-exhaust tune.',
  ),
  Configuration(
    id: 'ktm-stock',
    bikeId: 'ktm',
    name: 'Stock · Euro 5b reference',
    shortName: 'Stock (platform reference)',
    parts: ['Factory ECU', 'Stock catalyst / exhaust', 'Stock intake'],
    points: _ktm(false),
    source: ktmSource,
    reportedPeaks: '36.9 hp @ 8,693 RPM · 34.87 N·m @ 6,461 RPM',
    notes:
        'Stock KTM 390 Euro 5b reference. Adventure R fitment is confirmed for the kit, but the chart does not identify which 390 model was tested.',
  ),
  Configuration(
    id: 'ktm-coober',
    bikeId: 'ktm',
    name: 'COOBER LM ECU + DeCat',
    shortName: 'COOBER + DeCat',
    upgraded: true,
    baselineConfigId: 'ktm-stock',
    gainSummary:
        'Publisher peaks: 36.9 → 39.1 hp (+2.2 hp). Plotted power is torque-derived because the source power scale is uncertain.',
    parts: [
      'COOBER LM ECU',
      'COOBER DeCat header',
      'No intake change specified',
    ],
    points: _ktm(true),
    source: ktmSource,
    reportedPeaks: '39.1 hp @ 9,648 RPM · 36.23 N·m @ 6,284 RPM',
    notes:
        'The 2025+ kit pairs the LM ECU with a replacement catalyst-delete exhaust header. An intake modification is not listed as required. The seller recommends installing the latest KTM mapping first. Closed-course hardware; follow the supplier’s use restrictions.',
  ),
  ...researchedConfigurations,
];
Configuration configById(String id) => configurations.firstWhere(
  (c) => c.id == id,
  orElse: () => configurations.first,
);

class EditorialPick {
  const EditorialPick(
    this.title,
    this.configId,
    this.reason, {
    this.weightPresetId,
  });
  final String title, configId, reason;
  final String? weightPresetId;
}
