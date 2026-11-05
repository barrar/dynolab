import 'dart:convert';
import 'dart:typed_data';
import 'dyno_data.dart';
import 'share_catalog.dart';

const sharedStateVersion = 1;
const _metrics = ['both', 'power', 'torque'];
const _scales = [1, 10, 100, 1000, 10000, 100000, 1000000];
const _maxSafeInteger = 0x1fffffffffffff;

/// Packs values and numeric IDs instead of JSON keys and long catalog names.
/// Only comparison settings are shared. Preset weights are implicit.
String encodeSharedState(Map<String, dynamic> state) {
  final value = _validatedState(state);
  if (value == null) throw ArgumentError('Invalid shared settings');
  final runs = value['runs'] as List;
  final rider = (value['riderLb'] as num).toDouble();
  final gear = (value['gearLb'] as num).toDouble();
  final options =
      _metrics.indexOf(value['metric'] as String) |
      (value['normalizeByWeight'] == true ? 4 : 0) |
      (value['includeLoad'] == true ? 8 : 0) |
      (rider != 0 ? 16 : 0) |
      (gear != 0 ? 32 : 0);
  final writer = _Writer()..uint(options);
  if (rider != 0) writer.number(rider);
  if (gear != 0) writer.number(gear);
  for (final run in runs) {
    final config = sharedConfigurationIds.indexOf(run['id'] as String);
    if (config < 0) throw ArgumentError('Missing permanent configuration ID');
    final preset = run['weightPresetId'] == 'custom'
        ? -1
        : sharedWeightReferences.indexWhere(
            (p) =>
                p.id == run['weightPresetId'] && p.weightLb == run['weightLb'],
          );
    if (preset < 0 && run['weightPresetId'] != 'custom') {
      throw ArgumentError('Missing permanent weight preset ID');
    }
    writer.uint((config < 31 ? config : 31) + (preset + 1) * 32);
    if (config >= 31) writer.uint(config - 31);
    if (preset < 0) writer.number((run['weightLb'] as num).toDouble());
  }
  return base64Url.encode(writer.bytes).replaceAll('=', '');
}

String? sharedStateFromUrl(Uri url) =>
    url.pathSegments.length == 1 ? url.pathSegments.single : null;

Uri urlWithSharedState(Uri url, String encoded) {
  final query = {
    for (final entry in url.queryParametersAll.entries)
      if (entry.key != 's' && entry.key != 'state') entry.key: entry.value,
  };
  return Uri(
    scheme: url.scheme,
    userInfo: url.userInfo,
    host: url.hasAuthority ? url.host : null,
    port: url.hasPort ? url.port : null,
    path: '/$encoded',
    queryParameters: query.isEmpty ? null : query,
    fragment: url.hasFragment ? url.fragment : null,
  );
}

Map<String, dynamic>? decodeSharedState(String? encoded) {
  if (encoded == null ||
      encoded.isEmpty ||
      encoded.length > 16000 ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(encoded)) {
    return null;
  }
  try {
    final bytes = base64Url.decode(base64Url.normalize(encoded));
    if (base64Url.encode(bytes).replaceAll('=', '') != encoded) return null;
    return _validatedState(_readCompact(bytes));
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _readCompact(Uint8List bytes) {
  final reader = _Reader(bytes);
  final options = reader.uint();
  if (options >= 64 || options & 3 == 3) {
    throw const FormatException('Unknown options');
  }
  final rider = options & 16 != 0 ? reader.number() : 0.0;
  final gear = options & 32 != 0 ? reader.number() : 0.0;
  final runs = <Map<String, dynamic>>[];
  while (!reader.finished) {
    if (runs.length == 4) {
      throw const FormatException('Too many comparisons');
    }
    final packed = reader.uint();
    var config = packed % 32;
    if (config == 31) config += reader.uint();
    final id = sharedConfigurationIds[config];
    final presetCode = packed ~/ 32;
    String presetId;
    double weight;
    if (presetCode == 0) {
      presetId = 'custom';
      weight = reader.number();
    } else {
      final preset = sharedWeightReferences[presetCode - 1];
      presetId = preset.id;
      weight = preset.weightLb;
      final reference = weightPresets
          .where((p) => p.id == presetId)
          .firstOrNull;
      if (reference != null && reference.bikeId != configById(id).bikeId) {
        throw const FormatException('Preset belongs to another bike');
      }
      // Historical links keep their original mass if a catalog weight changes.
      final current = weightPresetsFor(
        configById(id).bikeId,
      ).where((p) => p.id == presetId).firstOrNull;
      if (current == null || current.weightLb != weight) presetId = 'custom';
    }
    runs.add({'id': id, 'weightLb': weight, 'weightPresetId': presetId});
  }
  return {
    'version': sharedStateVersion,
    'metric': _metrics[options & 3],
    'normalizeByWeight': options & 4 != 0,
    'includeLoad': options & 8 != 0,
    'riderLb': rider,
    'gearLb': gear,
    'runs': runs,
  };
}

class _Writer {
  final bytes = <int>[];
  void uint(int value) {
    if (value < 0 || value > _maxSafeInteger) {
      throw const FormatException('Invalid integer');
    }
    do {
      final low = value % 128;
      value ~/= 128;
      bytes.add(low + (value > 0 ? 128 : 0));
    } while (value > 0);
  }

  void number(double value) {
    for (var precision = 0; precision < _scales.length; precision++) {
      final scaled = value * _scales[precision];
      if (!scaled.isFinite || scaled > _maxSafeInteger ~/ 8) break;
      final integer = scaled.round();
      if (integer / _scales[precision] == value) {
        uint(integer * 8 + precision);
        return;
      }
    }
    uint(7);
    bytes.addAll(
      (ByteData(8)..setFloat64(0, value, Endian.little)).buffer.asUint8List(),
    );
  }
}

class _Reader {
  _Reader(this.bytes);
  final Uint8List bytes;
  var offset = 0;
  bool get finished => offset == bytes.length;
  int uint() {
    var value = 0, factor = 1;
    for (var i = 0; i < 8; i++) {
      final byte = bytes[offset++];
      value += (byte % 128) * factor;
      if (value > _maxSafeInteger) break;
      if (byte < 128) {
        if (i > 0 && byte == 0) {
          throw const FormatException('Noncanonical integer');
        }
        return value;
      }
      factor *= 128;
    }
    throw const FormatException('Oversized integer');
  }

  double number() {
    final code = uint(), precision = code % 8;
    if (precision != 7) return (code ~/ 8) / _scales[precision];
    if (code != 7) throw const FormatException('Unknown number format');
    final value = ByteData.sublistView(
      bytes,
      offset,
      offset + 8,
    ).getFloat64(0, Endian.little);
    offset += 8;
    return value;
  }
}

Map<String, dynamic>? _validatedState(Object? decoded) {
  if (decoded is! Map<String, dynamic> ||
      decoded['version'] != sharedStateVersion) {
    return null;
  }
  final runs = decoded['runs'];
  if (runs is! List || runs.isEmpty || runs.length > 4) return null;
  final knownConfigs = configurations
      .where((c) => c.hasCurve)
      .map((c) => c.id)
      .toSet();
  for (final run in runs) {
    if (run is! Map<String, dynamic> ||
        !knownConfigs.contains(run['id']) ||
        !_number(run['weightLb'], positive: true) ||
        run['weightPresetId'] is! String) {
      return null;
    }
    final c = configById(run['id'] as String);
    final presetId = run['weightPresetId'];
    if (presetId != 'custom' &&
        !weightPresetsFor(c.bikeId).any(
          (p) =>
              p.id == presetId &&
              p.weightLb == (run['weightLb'] as num).toDouble(),
        )) {
      return null;
    }
  }
  if (!['both', 'power', 'torque'].contains(decoded['metric']) ||
      decoded['normalizeByWeight'] is! bool ||
      decoded['includeLoad'] is! bool ||
      !_number(decoded['riderLb']) ||
      !_number(decoded['gearLb'])) {
    return null;
  }
  // Ignore unknown keys instead of allowing transient state into shared links.
  return {
    'version': sharedStateVersion,
    for (final key in [
      'metric',
      'normalizeByWeight',
      'includeLoad',
      'riderLb',
      'gearLb',
    ])
      key: decoded[key],
    'runs': [
      for (final run in runs)
        {
          for (final key in ['id', 'weightLb', 'weightPresetId']) key: run[key],
        },
    ],
  };
}

bool _number(Object? value, {bool positive = false}) =>
    value is num && value.isFinite && (positive ? value > 0 : value >= 0);
