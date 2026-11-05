import 'dart:convert';
import 'dart:io';
import 'package:dyno_lab/share_state.dart';

Map<String, dynamic> exampleState({bool custom = false, bool load = false}) => {
  'version': 1,
  'metric': custom ? 'power' : 'both',
  'normalizeByWeight': load || custom,
  'includeLoad': load || custom,
  'riderLb': custom
      ? 200.0
      : load
      ? 181.0
      : 0.0,
  'gearLb': custom
      ? 20.0
      : load
      ? 22.0
      : 0.0,
  'runs': [
    {
      'id': custom ? 'honda-stage1' : 'honda-stock',
      'weightLb': custom ? 350.0 : 333.0,
      'weightPresetId': custom ? 'custom' : 'honda-rally',
    },
    {
      'id': 'ktm-stock',
      'weightLb': custom ? 354.0 : 363.8,
      'weightPresetId': custom ? 'custom' : 'ktm-enduro',
    },
    if (custom)
      {
        'id': 'honda-cbr650r-stock-2019',
        'weightLb': 455.0,
        'weightPresetId': 'research-weight-honda-cbr650r-stock-2019',
      },
  ],
};

void main() {
  for (final entry in <String, Map<String, dynamic>>{
    'Two preset bikes': exampleState(),
    'Two preset bikes + rider and gear': exampleState(load: true),
    'Three bikes, two custom weights + rider and gear': exampleState(
      custom: true,
    ),
  }.entries) {
    final state = entry.value;
    final original = {
      ...state,
      'unit': 'lbFt',
      'runs': [
        for (var i = 0; i < (state['runs'] as List).length; i++)
          {...state['runs'][i], 'color': i, 'visible': true},
      ],
      'view': {
        'panel': 'comparison',
        'sourceId': 'honda-stock',
        'category': 'All',
        'query': '',
      },
    };
    final old = base64Url
        .encode(utf8.encode(jsonEncode(original)))
        .replaceAll('=', '');
    final compact = encodeSharedState(state);
    final oldUrl = 'https://moto.bendtrailmaps.com/?state=$old';
    final newUrl = urlWithSharedState(
      Uri.parse('https://moto.bendtrailmaps.com/'),
      compact,
    ).toString();
    if (jsonEncode(decodeSharedState(compact)) != jsonEncode(state)) {
      throw StateError('Settings did not round-trip');
    }
    stdout.writeln(
      jsonEncode({
        'example': entry.key,
        'oldStateCharacters': old.length,
        'newStateCharacters': compact.length,
        'oldUrlCharacters': oldUrl.length,
        'newUrlCharacters': newUrl.length,
        'stateReductionPercent': 100 * (1 - compact.length / old.length),
        'url': newUrl,
      }),
    );
  }
}
