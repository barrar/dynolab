# Research, data, and numerical maintenance

For the complete start-to-finish task sequence, examples and interrupted-work handoff, use the [catalog maintenance runbook](catalog-maintenance-runbook.md). This guide defines the evidence and numerical contract it follows.

The dataset is curated from published evidence. The app does not scrape publishers at runtime, estimate an engine curve from peak specifications, or claim access to original dynamometer run files. Research happens during development; reviewed records and chart assets are bundled into the release.

## What counts as evidence

Start with the original test publisher, dyno operator, tune manufacturer, or vendor publishing the actual run. Typical sources already used include Cycle World, Dirt Rider, Rider / Jett Tuning, 550 Performance, COOBER / Slavens, Rottweiler, and an OEM-compatible exhaust manufacturer's dyno PDF. Manufacturer model specifications and owner manuals supply weight/identity evidence, not independent wheel-horsepower measurements.

For each candidate, establish:

1. Exact model, test/model year, engine generation/displacement, market, and whether the source actually identifies the motorcycle.
2. Stock versus modified hardware: ECU/remap/controller, map version, fuel grade, full exhaust versus slip-on/decat, intake/filter/airbox changes, and other relevant engine work.
3. Whether the graph measures rear-wheel output, crank/engine output, an estimate, or an unspecified basis.
4. RPM/power/torque units, correction standard, smoothing, axis ranges, and a readable trace/legend.
5. A stable publisher URL, original chart/PDF URL, date reviewed, and local evidence asset when available.
6. A weight with its own source and basis: measured wet, claimed curb, equipment/fuel level, market, and exact body variant.

Search results and secondary writeups help locate evidence. They do not replace a primary trace with known axes. Re-open the original sources when expanding the catalog; product compatibility and U.S. availability change over time. Preserve the date of the reviewed evidence.

Hardware fitment and measured output are separate facts. An ECU sold for a 2025 Adventure R does not prove an unlabeled 390 platform chart was tested on that body model. A vendor's "all models" title does not make an older 373 cc Duke test a 399 cc Euro 5b test.

## Plot a curve or keep a source-only record

| Evidence | Treatment |
| --- | --- |
| Readable primary RPM trace with identified units and sufficient samples | Candidate curve; retain the method, caveats, and exact tested context |
| Product page with claimed peaks but no accessible RPM trace | Source-only, `points: []` |
| Hardware package documented but original graph unavailable | Source-only; record exactly which hardware is verified |
| Speed-axis graph with ambiguous gearing or secondary RPM scale | Source-only until RPM indexing can be established |
| Wrong engine generation or unclear wheel/crank basis | Keep separate and label, or withhold plotting until resolved |
| Manufacturer crank specification | Reference claim only; do not mix into a measured wheel curve |

No original full curve is available for several initial records, including the CRF300F and specific KTM tune packages. Their presence in the library documents a research result, not a promise of a drawable comparison. The initial [KTM research](ktm390-expansion.md) explains the individual cases.

## Digitize a chart

The existing process is manual chart inspection and sampling. There is no maintained automatic chart-digitization tool in this repo. The generator validates structured data and emits Dart; it does not download charts or extract pixels.

1. Obtain the publisher's graph or PDF and preserve the source link. Use an original image where possible. Render PDF graph pages at a readable resolution before taking measurements.
2. Inspect the legend and calibrate pixel locations against multiple labeled axis ticks. Confirm linear versus logarithmic axes and whether both vertical axes use different units.
3. Identify the exact stock or modified trace. A red/green/blue line is not inherently stock. For example, Rottweiler's red comparison already includes exhaust hardware; it must not be described as a fully stock motorcycle.
4. Sample the readable source domain, commonly near 500 RPM intervals, adding useful points near visible bends/peaks. Do not invent data at idle, zero RPM, beyond the graph, or through an unreadable limiter drop.
5. Record the original sampled values and their units. Store application samples as `[rpm, hp, torqueNm]`.
6. Where only one physical quantity is trustworthy, derive its counterpart with the formula below and disclose that dependence in `source.method`. Derived torque is not an independently measured second trace.
7. Compare sampled maxima with the publisher's printed maxima. Retain both as separate values and investigate discrepancies. Do not force sampled points to match a header by silently stretching an axis.
8. Save the asset under `assets/charts/`, and document uncertainty from resolution, line thickness, calibration, rounding, or an unknown tested variant.

Most original expansion horsepower readings were rounded to 0.1 hp, with torque derived and stored to a few decimals. The 550 Honda chart was sampled in both quantities. The original COOBER chart has conflicting power-scale/header information; its numerical input uses the readable dotted torque traces and derives horsepower. Those are source-specific choices, documented in [original research](research.md). Convert metric PS or kW into mechanical horsepower before storing `hp`; retain the source unit and conversion in the evidence instead of treating all printed power labels as interchangeable.

### Sampling ledger

Later digitization retains calibration evidence in [`dyno-sampling.json`](dyno-sampling.json). Each entry records a chart identity and asset, sampling canvas size, selected trace color, power-to-mechanical-hp factor, axis calibration, and `[rpm, xPixel, yPixel]` samples. The seven-value `axis` array describes `[x0, rpm0, x1, rpm1, yAtZeroPower, yAtReferencePower, referencePower]` for a linear chart.

For that calibration, `sourcePower = (yAtZeroPower - yPixel) × referencePower / (yAtZeroPower - yAtReferencePower)`. Apply the recorded power conversion factor to obtain mechanical HP. Pixel coordinates refer to the recorded sampling canvas; changing image scaling without updating them invalidates calibration. A zero-power intercept may lie below a cropped chart; establish it from the visible labeled ticks rather than treating the bottom image edge as zero. The ledger is evidence to inspect alongside the JSON points, not an automatically executed input to `import_research.py`. Keep it with the charts and reviewed records when correcting samples.

`python3 scripts/verify_sampling.py` replays this later ledger against the expansion JSON, checking calibrated X positions, rounded HP, derived torque, references and pixel bounds. It uses only the Python standard library and does not modify files. It does not inspect the image itself or validate which trace was selected. It currently covers 31 curves / 402 points; the original 25 curves / 405 points have their own earlier methodology and are not implicitly validated by this replay. `--root PATH` checks an isolated copy of the inputs.

The images are evidence, not precision guarantees. Avoid assigning an exact error bound unless independently established. No original `.drf` or equivalent data export was obtained for the initial dataset. Chart rights remain with their publishers; keep attribution and review redistribution permissions when changing how assets are distributed.

## Files and generation

The four original Honda/KTM configurations and their raw arrays live in [`lib/dyno_data.dart`](../lib/dyno_data.dart). The expanded library comes from research JSON and is emitted into [`lib/researched_data.dart`](../lib/researched_data.dart).

The current importer loads the following inputs relative to the project root:

| Input | Role |
| --- | --- |
| `docs/adventure-expansion.json` | Initial adventure evidence and samples |
| `docs/dual-sport-expansion.json` | Dual-sport and requested-model evidence and samples |
| `docs/ktm390-expansion.json` | Additional older-generation KTM evidence and samples |
| `docs/catalog-expansion.json`, when present | Additional catalog records |
| `docs/tuning-expansion.json`, when present | Additional upgrade records |
| `docs/catalog-families.json` | Required aliases, family display metadata, model weight presets, and weight labels |
| `docs/tune-coverage.json` | Required family-keyed research notes; coverage must match every resulting family plus the original Honda and KTM families |
| `docs/dyno-sampling.json` | Later pixel/calibration evidence; preserved for review, not consumed by the Dart generator |
| `assets/charts/` | Local assets referenced by source records |

The importer skips absent expansion files but reads the family/coverage files unconditionally. If one is missing, restore or complete that research input; do not replace a generated catalog with a partial reconstruction. Keep the generated file and all required generation inputs together when handing off work. The generator is not a substitute for checking source accuracy.

Run after reviewed input changes:

```sh
python3 scripts/verify_sampling.py
python3 scripts/import_research.py
dart format lib/researched_data.dart
dart scripts/audit_dyno.dart
flutter analyze
flutter test
```

Stop if generation fails. Check outputs before rebuilding. The importer rewrites the generated file; hand edits there will be lost. The audit also overwrites its three reports, so review their diff before release. Do not run Python with optimizations that disable assertions: several importer validations currently use `assert`.

### Record shape

The following is a source-only template, **not verified motorcycle data**. Replace every placeholder with researched evidence before importing it:

```json
{
  "id": "stable-model-build-test-id",
  "bikeId": "stable-family-id",
  "make": "Manufacturer",
  "name": "Model family",
  "years": "Actual tested generation or evidence year",
  "displacement": "Verified engine capacity",
  "configName": "Build, publisher, and test year",
  "shortName": "Short build label",
  "upgraded": true,
  "parts": ["Exact ECU/map", "Exact exhaust", "Exact intake hardware"],
  "points": [],
  "source": {
    "publisher": "Original publisher",
    "url": "https://example.com/replace-with-primary-source",
    "imageUrl": "",
    "asset": "",
    "method": "No verified primary RPM trace; source-only.",
    "caveat": "Describe the missing evidence and known limitations."
  },
  "reportedPeaks": "No verified measured peaks.",
  "notes": "Describe test context, compatibility, and uncertainty.",
  "measurementBasis": "No measured curve",
  "weightLb": 0,
  "weightBasis": "No verified wet weight; source-only.",
  "weightSourceUrl": "https://example.com/replace-with-weight-source",
  "usSourceUrl": "https://example.com/replace-with-oem-model-page",
  "category": "Research",
  "editorialPick": false
}
```

For a drawable record, supply at least two strictly ascending positive RPM points with finite nonnegative values and a verified positive default weight. The importer checks ascending order, number finiteness, record IDs, some required fields, HTTPS source URLs, referenced asset existence, baseline references, and family research coverage. It does not check every scientific assumption; the runtime audit and tests supply further checks.

Optional metadata includes `selectionReason`, `weightLabel`, `defaultWeightPresetId`, `baselineConfigId`, and `gainSummary`. Use a known baseline ID only when the comparison claim is supported. A `defaultWeightPresetId` references an existing preset instead of generating a new `research-weight-<id>` preset.

Group model weights under a family only when the family identity is justified, and retain the tested variant/calibration in each configuration. Catalog aliases affect generated bike identities and default weights; review them together with URL reference compatibility. Do not merge different engine generations just because they share a marketing number.

### Weight evidence

Prefer the actual tested wet weight when available, or clearly label a manufacturer wet/curb reference. Do not substitute dry or without-fuel figures into a wet comparison. State extra equipment, fuel basis, ABS/DCT/body variants, and market differences. Do not assume an upgraded exhaust saves a particular mass; use the reference weight until an actual modified mass is known or entered by the user.

Model presets can share numerical values while retaining different historical IDs. `modelPresetsFor` removes duplicate label/weight combinations from the displayed menu while allowing an active historical ID to remain valid. Shared preset reference masses are frozen separately in the [sharing codebook](../lib/share_catalog.dart).

## Physics and reconciliation contract

Internal torque is N·m. The constants used by the app are:

```text
nmPerLbFt = 1.3558179483
hpRpmPerNm = 7120.9092

torqueNm = torqueLbFt × nmPerLbFt
torqueImpliedByHpNm = recordedHp × hpRpmPerNm / rpm
averagedTorqueNm = (recordedTorqueNm + torqueImpliedByHpNm) / 2
calculatedHp = averagedTorqueNm × rpm / hpRpmPerNm
```

Preserve `recordedPoints`; compute adjustments into `points`. Never feed already averaged points back in as fresh source data, because that would apply the reconciliation again and erase the baseline for the report.

The user requires a report of numerical changes and percentages. **Any difference over five percent must be reported before applying the change.** The implemented gate is deliberately conservative: it checks the absolute raw torque discrepancy, averaged torque adjustment, and resulting HP adjustment. `TorqueReconciliation.apply()` throws when any exceeds five percent. The audit also compares interpolated horsepower with the previous linear-HP interpretation at 1 RPM intervals and flags a curve if that difference exceeds five percent.

Percentages use their original recorded value as the denominator:

```text
raw torque discrepancy % = 100 × (implied torque − recorded torque) / recorded torque
torque adjustment % = 100 × (averaged torque − recorded torque) / recorded torque
HP adjustment % = 100 × (calculated HP − recorded HP) / recorded HP
```

The runtime treats a zero baseline changing to a nonzero value as an infinite discrepancy. Do not add a zero-RPM sample: torque-from-horsepower requires positive RPM. Do not disable the gate to make a new record load. Prepare the report, inspect units/axis calibration, and obtain the user's decision before applying a change above the threshold.

The original November 2 audit contains **405 points across 25 curves**, all below the gate. That is a historical baseline, not a permanent expected catalog size. It found maximum original Honda torque adjustments of approximately +0.501% for stock and −0.379% for Stage 1.0. Most derived expansion torques changed only by rounding noise. Consult the current generated audit for later additions; update fixed-count tests deliberately with reviewed data changes.

## Interpolation, peaks, and weight ratios

Between two source points, interpolate **averaged torque** linearly and derive horsepower from that torque and RPM. This makes horsepower quadratic in RPM. The painter's quadratic Bézier representation and the peak search reflect the same function. Never independently linearly interpolate HP in tooltips while drawing or calculating it differently elsewhere.

Outside the sampled domain, return no value. Blank CSV cells and "No data at this RPM" are intentional. Printed peak metadata is displayed separately from maxima computed from sampled/reconciled curves.

```text
totalLb = bikeLb + (includeLoad ? riderLb + gearLb : 0)
hpPer100Lb = 100 × calculatedHp / totalLb
torqueLbFtPer100Lb = 100 × (averagedTorqueNm / nmPerLbFt) / totalLb
```

Add the shared load once per bike, not once per plotted quantity. Weight presets alter the denominator only. These ratios do not model acceleration, gearing, traction, drag, aerodynamics, or rider position.

## Audit outputs and release review

`dart scripts/audit_dyno.dart` produces:

- [`dyno-consistency-audit.md`](dyno-consistency-audit.md): per-curve maxima, signed torque adjustments, review status, and interpolation comparison.
- [`dyno-consistency-audit.json`](dyno-consistency-audit.json): every original/derived value and percentage at full precision.
- [`dyno-consistency-points.csv`](dyno-consistency-points.csv): per-point report formatted for reading, with three significant figures.

Exit code **2** means review is required. It is not a successful release gate. The audit can generate its report without calling the guarded `apply()` path, allowing reviewers to see discrepancies before accepting data.

Before releasing a data update, inspect the original chart beside the samples, review every material adjustment, confirm hardware and weight provenance, run the checks, append any needed permanent shared IDs, rebuild, and publish only when authorized. New configuration and weight codes belong at the end of their codebooks. Do not reorder existing codes or change a frozen reference mass.

The [development guide](development.md) maps these changes to tests; the [deployment guide](deployment.md) explains publication. Research JSON edits alone do not change a compiled or deployed site.
