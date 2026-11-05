# Repeatable motorcycle and tune research

Use this runbook for a request to add motorcycles, group related models, refine weights, or find aftermarket horsepower gains. The [data workflow](data-workflow.md) defines evidence and numerical rules; [current state](current-state.md) identifies the completed catalog and remaining research gaps. This procedure does not require publishing a release.

## 1. Establish the starting state

Read [architecture](architecture.md), [project decisions](project-history.md), and the most recent dated research report before editing. Inspect all five expansion inputs, `catalog-families.json`, `tune-coverage.json`, and the permanent IDs in `lib/share_catalog.dart`. The four original Honda/KTM records are in `lib/dyno_data.dart`, outside the JSON importer.

Record the requested models, engine generations, markets, number of desired tune results, and any requested analysis range. For this task, the target was two aftermarket setups per family, with one or none acceptable when evidence was absent. A family-wide search outcome is required even when no curve can be added. An aftermarket setup can include exhaust, intake, cams, or displacement changes; list the complete hardware rather than crediting all gains to an ECU alone.

Check repository status before editing and preserve unrelated work. This project originally had no `.git` directory; Git history begins with the November 5, 2026 GitHub publication. Use the complete Flutter SDK described in [development](development.md#toolchain).

## 2. Search every family and keep an evidence log

Build the family inventory from the application, including source-only families. Search the exact model/year/engine together with terms such as `dyno`, `before after`, `ECU flash`, `tune`, `power commander`, and relevant tuner names. Check the tuner or manufacturer publication, its graph assets, and exact fitment. Search snippets and retailer fitment alone cannot establish a measured gain. Recheck existing source-only leads before assuming nothing new exists.

Create a dated `docs/tuning-research-YYYY-MM-DD.md`. Use a row for every family and a separate row for each accepted setup. A useful research-log shape is:

| Field | What to record |
| --- | --- |
| Family and tested motorcycle | Stable family ID, exact body model, year, engine generation, market and fuel |
| Source reviewed | Publisher, page URL, graph/PDF URL, access date and local asset |
| Setup and comparison | Full parts, calibration/stage, fuel, baseline hardware, and whether runs are actually paired |
| Numerical evidence | Published stock/tuned peaks with units and RPM; readable sampled RPM domain |
| Decision | Plotted curve, source-only reading, rejected evidence, or no usable result found |
| Reason and next lead | Missing axes, unclear wheel/crank basis, inaccessible chart, different generation, or next primary source worth checking |

Count distinct evidenced setups, not repeated reseller pages or the same chart republished elsewhere. Two body variants or fuel calibrations can be separate tested setups, but must remain labeled. Do not imply two results for every variant just because two were found for a shared family. A statement that no usable evidence was found describes this search, not proof that no tune exists.

## 3. Group families while keeping tested identity

Use one family for related engine-platform variants where a shared selection is useful. Keep materially different generations separate: the 373 cc KTM 390 family and the newer 399 cc Euro 5b family remain separate. Within KTM 890, Adventure and Duke factory calibrations keep separate tested runs even though they share the family selector.

`docs/catalog-families.json` contains four independent maps/lists:

| Key | Meaning |
| --- | --- |
| `aliases` | A legacy input `bikeId` mapped to the canonical family ID. Resolution is one hop; use the final ID directly. |
| `families` | Display overrides for generated `Bike` fields: `make`, `name`, `years`, `displacement`. The original Honda/KTM family declarations remain in Dart. |
| `weights` | Additional model presets, each with `id`, canonical `bikeId`, `label`, `weightLb`, `basis`, `sourceUrl`. |
| `weightLabels` | Display-label overrides keyed by the generated preset ID; these do not change mass. |

The current family grouping includes:

```json
{
  "aliases": {"ktm-390-duke-373": "ktm-390-adventure-373"},
  "families": {"ktm-890-adventure-r": {"name": "890", "years": "2020–2026 references"}}
}
```

This is an excerpt, not a replacement for the full file. Preserve existing IDs even when a display name changes. Aliasing the family does not rename a configuration's tested body/year: keep those in `configName`, source metadata, hardware and notes.

Source mass independently from dyno power. Include the measurement year, wet/curb/dry basis, fuel, equipment and claimed-versus-measured status. Do not convert a dry mass into wet mass using a guessed fuel load. For a new tune using an existing mass reference, set `defaultWeightPresetId` to that preset instead of creating another identical reference. Without that field the importer creates `research-weight-<configuration-id>` from the record's weight fields.

`modelPresetsFor` collapses equal label/mass choices in the visible menu while preserving an active historical preset ID. Never remove old presets merely to simplify that menu. Model selection changes the comparison denominator only: **Model changes weight only. Dyno run keeps its tested bike and year.**

## 4. Record stock/tuned pairs and source-only results

Copy an appropriate complete record from `catalog-expansion.json` or `tuning-expansion.json`, then review every field. The [record schema](data-workflow.md#record-shape) has a source-only template. A row's `id` must be globally unique; `bikeId` identifies the family, not the particular tested run.

For a plotted tune, retain its same-source baseline as a separate record where available. The current KTM 890 Adventure pair illustrates the connection:

```json
{
  "id": "ktm890-bt-adv-stage1",
  "bikeId": "ktm-890-adventure-r",
  "baselineConfigId": "ktm890-bt-adv-stock",
  "upgraded": true
}
```

This is a field excerpt; it omits required source, weight, identity and point fields. Inspect the complete pair in [`tuning-expansion.json`](tuning-expansion.json) before copying it. `baselineConfigId` must name a real appropriate stock/baseline record. A paired baseline can already include hardware: describe it accurately. Two paired runs can have separate chart assets if publisher evidence connects them. Do not substitute an unrelated magazine stock run just to calculate a tune gain.

Use `gainSummary` for the publisher's before/after reading, unit/basis and important caveats. Preserve `reportedPeaks` separately from sampled graph maxima. The app's **Add matching stock run** action uses the linked baseline with the comparison's selected mass. Verify that link and mass in the browser.

For source-only evidence, keep `points: []`, explain the missing evidence, and retain the source and any supportable peak reading. Do not create a baseline link or percentage gain that the source does not establish. A verified positive mass is necessary for a drawable comparison; an unknown-weight source-only record may use the documented zero placeholder and must remain non-plottable.

## 5. Sample and review charts

Follow [manual digitization](data-workflow.md#digitize-a-chart). Save the original graph, identify its exact power trace/legend, verify axes against multiple ticks, and compare approximate sampled maxima against printed maxima. The Husqvarna 701 correction in [the November 3 report](tuning-research-2026-11-03.md) demonstrates why a plausible-looking torque trace must not be accepted as power.

For the later power-derived curves, add an entry to `docs/dyno-sampling.json` with the asset, canvas, color/trace identity, calibration, unit factor and `[rpm, x, y]` samples. Store JSON points as `[rpm, mechanicalHp, torqueNm]`, rounding power to 0.1 hp before deriving torque with `hp * 7120.9092 / rpm`. PS/CV uses `0.9863200706` mechanical hp per unit. This rule describes the later power-sampling ledger; do not apply it blindly to older independently sampled HP/torque or torque-first records.

Run the maintained arithmetic/transcription check:

```sh
python3 scripts/verify_sampling.py
```

It checks ledger references/assets, point counts, ordered/bounded RPM, pixel bounds, X calibration within half a pixel, rounded horsepower and derived torque. It requires all five current expansion files, deliberately catching a partial handoff. The script does not download images, inspect their pixels, confirm legends, measure uncertainty, or verify the 25 earlier curves without ledger entries. It does not modify inputs. A successful replay still needs visual source review.

## 6. Integrate without breaking shared links

Update `docs/tune-coverage.json` for every resulting canonical family, including explicit gaps and rejected leads. The importer checks that its keys match all families, including original `honda` and `ktm`.

Append new configuration IDs and new preset IDs/masses to the end of the corresponding arrays in `lib/share_catalog.dart`. Keep all existing order and reference masses frozen. Source-only configurations are also catalog records and should have permanent IDs. When a mass reference needs a corrected value, create a new preset ID/reference rather than changing bytes that existing links resolve. Read [compact sharing](compact-sharing.md) for details.

Generate and validate in this order, stopping on failure:

```sh
python3 scripts/verify_sampling.py
python3 scripts/import_research.py
dart format lib/researched_data.dart
dart scripts/audit_dyno.dart
flutter analyze
flutter test
flutter build web --wasm --release --no-web-resources-cdn
```

Use ordinary Python, not `python -O`; the importer relies on assertions. Its expansion-file list is explicit, so adding another JSON filename does not automatically import it. It accepts lists or a dictionary containing `entries` / `configurations`. It does not fetch evidence or fully validate model identity, weight references, paired-run suitability or sharing IDs; tests and source review cover those responsibilities. Regenerate twice and compare the formatted generated output when changing the importer itself.

The audit writes Markdown, JSON and CSV. Any raw discrepancy, torque adjustment, resulting HP adjustment or intermediate check over the user's five-percent threshold requires reporting and a user decision before applying. A review flag is not resolved by changing expected counts or disabling the gate. Review the detailed [numerical contract](data-workflow.md#physics-and-reconciliation-contract).

Tests cover family/coverage completeness, baselines, old aliases/presets, weight-only model changes, matching-stock mass, source-only behavior and shared IDs. Update numeric totals only after confirming why the dataset changed. Use the actual complete test result in the handoff.

## 7. Check the UI and leave a resumable handoff

Serve the rebuilt release locally with `PORT=52742 ./scripts/serve.sh`, or use another free port. Check the library count, grouped family menu, variant labels/weights, unchanged run identity after changing model, Upgrades/More bikes filters, research outcome, source details and matching-baseline action. Check a narrow width after adding long labels/categories. Open and reload a direct comparison path and retain an old link/preset check when changing catalog IDs.

Update README totals, documentation links, dated research outcomes, audit outputs and [current state](current-state.md). Record exact checks and limitations. Keep source changes, the local build and a deployed release distinct. Publication requires the user's instruction and the [deployment workflow](deployment.md); a local build is not proof of a live release.

If interrupted, record changed inputs and generated files, last passing checks, unresolved evidence, pending UI/release steps and any temporary paths. Resume from the current files, preserving unrelated edits. Re-run checks whose inputs changed; do not restart the research or present old checks as newly performed. Temporary download/sampling scripts are not part of the maintained workflow unless intentionally added and documented.
