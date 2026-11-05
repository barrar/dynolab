part of 'main.dart';

class _LibraryItem {
  const _LibraryItem(
    this.config,
    this.title, {
    this.reason = '',
    this.presetId,
  });
  final Configuration config;
  final String title, reason;
  final String? presetId;
}

class LibraryDialog extends StatefulWidget {
  const LibraryDialog({
    super.key,
    required this.onSelect,
    required this.onSource,
    required this.canAdd,
    this.initialCategory = 'All',
    this.initialQuery = '',
    this.onViewChanged,
    this.onCopyLink,
  });
  final void Function(String configId, String? weightPresetId) onSelect;
  final ValueChanged<Configuration> onSource;
  final bool canAdd;
  final String initialCategory, initialQuery;
  final void Function(String category, String query)? onViewChanged;
  final VoidCallback? onCopyLink;
  @override
  State<LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<LibraryDialog> {
  late String category = widget.initialCategory, query = widget.initialQuery;
  late final queryController = TextEditingController(text: query);
  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void updateView({String? category, String? query}) {
    setState(() {
      this.category = category ?? this.category;
      this.query = query ?? this.query;
    });
    widget.onViewChanged?.call(this.category, this.query);
  }

  List<_LibraryItem> get items {
    List<_LibraryItem> result;
    if (category == 'Adventure' || category == 'Dual sport') {
      final picks = category == 'Adventure' ? adventurePicks : dualSportPicks;
      result = picks
          .map(
            (p) => _LibraryItem(
              configById(p.configId),
              p.title,
              reason: p.reason,
              presetId: p.weightPresetId,
            ),
          )
          .toList();
    } else {
      result = configurations
          .where(
            (c) =>
                category == 'All' ||
                (category == 'Upgrades' && c.upgraded) ||
                (category == 'More bikes' &&
                    configurations.any(
                      (entry) =>
                          entry.category == 'More bikes' &&
                          entry.bikeId == c.bikeId,
                    )) ||
                (category == '390 upgrades' &&
                    (c.bikeId == 'ktm' || c.bike.name.startsWith('390'))) ||
                (category == 'Requested' &&
                    RegExp(
                      r'890|500|350|250F|300F|CBR650R',
                      caseSensitive: false,
                    ).hasMatch(c.bike.fullName)),
          )
          .map(
            (c) => _LibraryItem(c, c.bike.fullName, reason: c.selectionReason),
          )
          .toList();
    }
    result.sort((a, b) {
      final brandAndModel = a.config.bike.fullName.compareTo(
        b.config.bike.fullName,
      );
      return brandAndModel != 0
          ? brandAndModel
          : configurations.indexOf(a.config).compareTo(
              configurations.indexOf(b.config),
            );
    });
    final words = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return result.where((item) {
      final haystack =
          '${item.title} ${item.config.name} ${item.config.bike.years} ${item.config.parts.join(' ')} ${item.reason} ${weightPresetsFor(item.config.bikeId).map((p) => p.label).join(' ')}'
              .toLowerCase();
      return words.every(haystack.contains);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = items;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'The dyno library',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.onCopyLink != null)
                    IconButton(
                      key: const ValueKey('copy-library-link'),
                      onPressed: widget.onCopyLink,
                      tooltip: 'Copy page link',
                      icon: const Icon(Icons.link_rounded),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close library',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                'Explore U.S. adventure, dual-sport, trail and road bikes, plus researched tuning builds.',
                style: TextStyle(fontSize: 11, color: muted, height: 1.7),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('library-search'),
                controller: queryController,
                onChanged: (text) => updateView(query: text),
                decoration: InputDecoration(
                  hintText: 'Search bikes, model years, tuners or hardware',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final name in [
                      'All',
                      'Adventure',
                      'Dual sport',
                      '390 upgrades',
                      'Requested',
                      'Upgrades',
                      'More bikes',
                    ])
                      ChoiceChip(
                        label: Text(
                          name == 'Adventure'
                              ? 'Adventure · ${adventurePicks.length}'
                              : name == 'Dual sport'
                              ? 'Dual sport · ${dualSportPicks.length}'
                              : name,
                          style: const TextStyle(fontSize: 10),
                        ),
                        selected: category == name,
                        onSelected: (_) => updateView(category: name),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                category == 'Adventure' || category == 'Dual sport'
                    ? 'Editorial top 10 · U.S.-available model families, not a sales ranking. Published test years and weight references are shown for each run.'
                    : '${results.length} records · ${results.where((e) => e.config.hasCurve).length} digitized curves. Source-only entries remain available for research; peak numbers alone are never drawn as curves.',
                style: const TextStyle(fontSize: 10, color: muted, height: 1.7),
              ),
              const SizedBox(height: 10),
              if (category == 'Upgrades') ...[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Research coverage · ${bikes.length} families reviewed',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Reviewed November 3, 2026 · includes bikes with no verified result',
                    style: TextStyle(fontSize: 9, color: muted),
                  ),
                  children: [
                    SizedBox(
                      height: 220,
                      child: ListView(
                        children: [
                          for (final bike in bikes)
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(bottom: 8),
                              title: Text(
                                bike.fullName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                tuneResearch[bike.id] ?? '',
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Flexible(
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'No matching records. Try a different search.',
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const Divider(height: 26),
                        itemBuilder: (context, index) {
                          final item = results[index], c = item.config;
                          final plotReady =
                              c.hasCurve &&
                              isValidWeight(c.bike.referenceWeightLb);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _tag(
                                    plotReady ? 'CURVE READY' : 'SOURCE ONLY',
                                    plotReady
                                        ? const Color(0xFF26967A)
                                        : accent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${c.bike.years} · ${formatMeasurements(c.bike.displacement)} · ${c.name}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatMeasurements(c.reportedPeaks),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1.7,
                                ),
                              ),
                              if (item.reason.isNotEmpty) ...[
                                const SizedBox(height: 7),
                                Text(
                                  formatMeasurements(item.reason),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: muted,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 5,
                                runSpacing: 5,
                                children: [
                                  _tag(c.measurementBasis, ink),
                                  for (final part in c.parts) _tag(part, ink),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () => widget.onSource(c),
                                    child: const Text('Source & build details'),
                                  ),
                                  FilledButton(
                                    onPressed: widget.canAdd && plotReady
                                        ? () => widget.onSelect(
                                            c.id,
                                            item.presetId,
                                          )
                                        : null,
                                    child: Text(
                                      !plotReady
                                          ? 'No RPM curve to plot'
                                          : widget.canAdd
                                          ? 'Add to graph'
                                          : '4 runs selected',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
