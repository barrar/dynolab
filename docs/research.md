# Dyno sources and methodology

Reviewed November 2, 2026.

This document preserves the original Honda/KTM source review and the subsequent notes from that research phase. See [data workflow](data-workflow.md) for current maintenance procedures, [architecture](architecture.md) for current app behavior, and [compact sharing](compact-sharing.md) for the latest persistence contract. Later library additions keep their own model-generation caveats.

## Model selection

“Honda 300L” means Honda CRF300L (286 cc). The user confirmed “KTM 390 Rally” means the **2025+ KTM 390 Adventure R**, not the 2020–2024 373 cc Adventure. KTM’s [official specifications](https://www.ktm.com/en-qa/models/travel/2025-ktm-390-adventurer/technical-specifications.html) identify the new 398.7 cc engine. The original newer-generation comparison uses the separately caveated Euro 5b platform chart below. Later library expansion added explicitly labeled older 373 cc KTM tests; they are not substituted for this generation. Manufacturer crankshaft ratings are not converted into measured wheel curves.

## Honda CRF300L — 550 Performance Stage 1.0

Primary publisher: [550 Performance’s CRF300L tuning page](https://www.550performance.com/products/my21-ecu-tuning-honda-crf-300-l).

- [Original stock / Stage 1.0 chart](https://cdn.shopify.com/s/files/1/0602/0153/3687/files/550Performance_CRF300L_Stage1.0_DynoChart.png?v=1765738829)
- [Tune / hardware compatibility matrix](https://cdn.shopify.com/s/files/1/0602/0153/3687/files/TuneMatrix_R260625.png?v=1782409419)
- Bundled source chart: `assets/charts/honda-550-stage1.png`

| Configuration | Reported power peak | Reported torque peak |
| --- | --- | --- |
| Stock | 23.51 rear-wheel hp at 8,243 RPM | 17.90 lb-ft at 6,315 RPM |
| 91 AKI Stage 1.0 | 27.87 rear-wheel hp at 7,961 RPM | 20.08 lb-ft at 6,305 RPM |

The 91 AKI Stage 1.0 tune requires a compatible full performance exhaust, a high-flow airbox lid, and a high-flow velocity stack. The matrix allows a stock air filter; an aftermarket filter and high-flow snorkel are recommended. The stock silencer is incompatible with this configuration. The matrix lists compatible full systems including Graves/Yoshimura and Akrapovič. Fit the hardware and fuel grade that match the selected tune; this is distinct from 550’s stock-hardware tune.

The app uses approximate readings from the colored chart traces, with power and torque sampled separately and rounded. The common plotted range is 2,500–10,400 RPM, intentionally truncated before the source’s extreme endpoint. Printed peak numbers are retained in source details, not substituted for the sampled curve maximum.

## KTM 390 Euro 5b — COOBER LM ECU + DeCat

Primary vendor evidence:

- [Slavens Racing kit page, fitment, and published dyno chart](https://slavensracing.com/shop/ktm-390-cat-delete-kit-by-coober/)
- [Original COOBER chart](https://slavensracing.com/wp-content/uploads/2026/03/Coober-390-Cat-Delete-Dyno.png)
- [Manufacturer’s Adventure R 2025+ DeCat kit page](https://www.coober.eu/product/ktm-390-adv-eur5b-decat-kit/)
- Bundled source chart: `assets/charts/ktm-coober-dyno.png`

The kit includes the COOBER LM ECU and COOBER catalyst-delete exhaust header. The manufacturer specifies the 2025+ Adventure R / Euro 5b dual-lambda application. The vendor lists the 2025–2026 KTM Adventure R/X, Enduro R, and compatible Husqvarna 401 models. An intake modification is **not listed as required**. Slavens recommends the latest KTM mapping before installation. The exhaust modification is closed-course hardware; consult the supplier’s usage restrictions.

| Configuration | Header-reported power peak | Header-reported torque peak |
| --- | --- | --- |
| KTM_390EUR5B_STOCK | 36.9 hp at 8,693 RPM | 34.87 N·m at 6,461 RPM |
| KTM_390EUR5B_DECAT_LMECU | 39.1 hp at 9,648 RPM | 36.23 N·m at 6,284 RPM |

### Material limitations

1. The graph names the **390 Euro 5b platform**, not the tested Adventure R body model. Product fitment establishes compatibility, not proof that the pictured run was performed on an Adventure R. Both stock and upgraded KTM curves are explicitly labeled platform references in the app.
2. This source is only 600 × 600 pixels, with faint dotted torque lines. Digitization is approximate and has no independently validated numerical error bound.
3. The graph’s solid horsepower traces do not match its header peak horsepower figures when read against its displayed scale. Rather than silently rescale them, the app uses the dotted torque curves and computes horsepower from torque at the sampled RPMs. The original chart and conflicting header figures remain accessible.
4. The sampled KTM range ends at 9,800 RPM before the abrupt limiter falloff, avoiding unsupported readings near the endpoint.

## Numerical treatment

`lib/dyno_data.dart` contains all samples, units, source links, and caveats.

- Honda source lb-ft values are stored after conversion to N·m.
- `N·m = lb-ft × 1.3558179483`.
- KTM horsepower sample calculation: `hp = N·m × RPM / 7120.9092`.
- Current interpolation is linear in reconciled torque; horsepower is calculated from that torque and RPM, making each HP segment quadratic. See the reconciliation section below.
- Values outside each curve’s domain are absent. Readouts say “No data at this RPM”; curves do not extend beyond their samples.
- Both axes are explicit: horsepower on the left, torque on the right. Current UI torque is always pound-feet; there is no unit selector.
- CSV exports preserve the approximate nature of the data and include the source URLs.

The app does not claim that these different dynos, correction methods, tires, weather conditions, or test setups are directly comparable. No claimed crankshaft peaks are mixed into wheel-derived curves. There are no invented Adventure R-specific results or unsupported upgrade-gain claims.

## Power-to-weight view

The **Per 100 lb** mode multiplies horsepower and torque at each RPM by 100 and divides by that comparison’s total weight in pounds. All visible runs use one shared vertical scale. It is a power-to-weight ratio, not an acceleration simulation; gearing, drag and traction are not modeled. The weight toggle scales the reconciled curves without changing their underlying samples.

Starting weights are published wet references, excluding rider and luggage:

- Honda CRF300L: **309 lb**, the non-ABS curb weight in the [2021 Honda brochure](https://powersports.honda.com/-/media/products/family/crf300l-crf250l/brochure/2021/2021-crf300l-brochure.pdf). The same brochure lists 311 lb for ABS. Model years, market specifications and actual builds may differ.
- KTM 390 Adventure R: **388 lb**, rounded from **176 kg fully fueled** in [KTM’s 2025 specifications](https://www.ktm.com/en-qa/models/travel/2025-ktm-390-adventurer/technical-specifications.html). Dry and without-fuel figures are not mixed into these defaults.

Upgraded configurations start at the same bike reference weight; no exhaust or intake weight saving is assumed. Each comparison has its own editable weight, including when two runs use the same motorcycle. Changing the motorcycle resets its weight to that family’s default preset; switching a build on the same bike keeps the entered weight. Invalid input leaves the chart at its last valid weight and shows a validation message. Weights and the selected chart mode save in browser storage. CSV exports include both the entered weights and the normalized values.


## Model presets and optional shared load

The app now labels the KTM family **KTM 390 (2025+)**. Weight selections are independent of stock / upgraded dyno configurations. Selecting Rally or Enduro does not establish a model-specific dyno test: the existing chart provenance and limitations continue to apply.

| Family | Weight preset | Wet weight used | Primary reference |
| --- | --- | --- | --- |
| Honda CRF300L | Standard | 309 lb | [2021 Honda brochure](https://powersports.honda.com/-/media/products/family/crf300l-crf250l/brochure/2021/2021-crf300l-brochure.pdf) |
| Honda CRF300L | Standard ABS | 311 lb | Same Honda brochure |
| Honda CRF300L | Rally | 333 lb | Same Honda brochure |
| Honda CRF300L | Rally ABS | 337 lb | Same Honda brochure |
| KTM 390 | Adventure R | 388 lb | [2025 KTM Adventure R specs](https://www.ktm.com/en-qa/models/travel/2025-ktm-390-adventurer/technical-specifications.html), 176 kg fully fueled |
| KTM 390 | Enduro R | 363.8 lb | [2025 KTM Enduro R specs](https://www.ktm.com/en-us/models/dual-sport/2025-ktm-390-enduror/technical-specifications.html), 165 kg fully fueled |

Model years and markets can vary. All the preset values include fuel and fluids; none mixes dry or without-fuel weight into a wet-weight comparison. Custom weights remain available for changed parts or actual scale measurements. Manual bike-weight edits mark the selection Custom. Old saved weights are retained; matching published weights adopt the corresponding preset and other values stay Custom.

With **Include rider and gear** enabled, `total lb = bike lb + rider lb + gear/luggage lb` for every selected comparison, and `hp/100 lb = 100 × horsepower at RPM / total lb`. The shared values are added once per bike, rather than once per curve. When disabled, the denominator returns to bike weight while retaining the rider and gear entries. Zero is valid for either optional load field; negative and non-finite values are rejected. The weight toggle scales the reconciled curves without changing their underlying samples.

The shared toggle, rider and gear weights, model presets and custom weights persist locally. Exports identify whether the load was included and list the actual total denominator for each normalized curve.

## Expanded library and unified normalization

The current chart uses one **Per 100 lb** toggle for both physical quantities. For every selected run, with `W = bike lb + included rider lb + included gear lb`:

- `hp/100 lb = 100 × horsepower at RPM / W`
- `lb-ft/100 lb = 100 × torque in lb-ft at RPM / W`

Both metrics retain separate, shared axes so that every visible bike uses the same power scale and the same torque scale. Both raw and weighted axes, and the RPM domain, expand to cover the selected source curves. Both/Power/Torque are independent visibility controls. Existing saved normalization preferences use the per-100-pound scale.

The two ten-bike collections are editorial selections of U.S. model families, not a published sales ranking. The explicit test years, engine generations, historical body variants and wet-weight references are retained. The Husqvarna 701 reference is specifically the LR test with its larger fuel capacity; the 2020 Tiger 900, 2020 Africa Twin Adventure Sports ES and 937 cc DesertX are not presented as newly measured current-generation models.

Detailed primary-source evidence, exact graph samples and uncertainty are preserved in [adventure-expansion.md](adventure-expansion.md), [dual-sport-expansion.md](dual-sport-expansion.md), and [ktm390-expansion.md](ktm390-expansion.md). Source JSON is bundled into typed app data by `scripts/import_research.py`.

Source-only listings are intentionally not plottable: no unsupported curve is synthesized from reported peaks or an unclear road-speed axis. The CRF300F, BR Stage 2, Mantra Stage II and ECUWEST entries retain research evidence and their specific limitations. The independent 2020 stock Adventure and Rottweiler PCV full-hardware curves are distinct older 373 cc datasets, separate from the original 399 cc Euro 5b reference.


## Torque reconciliation and display precision

Original digitized samples remain immutable in `recordedPoints`. Every plotted source point uses:

- `HP-implied torque (N·m) = recorded HP × 7120.9092 / RPM`
- `averaged torque = (recorded torque + HP-implied torque) / 2`
- `calculated HP = averaged torque × RPM / 7120.9092`

Between source points, interpolate torque and derive horsepower from torque and RPM, rather than independently interpolating horsepower. The painter uses exact quadratic segments for the resulting horsepower curve. Peak calculations consider the interior of each segment as well as source samples.

The [audit](dyno-consistency-audit.md) reports every curve; its [CSV](dyno-consistency-points.csv) reports every point and its [JSON](dyno-consistency-audit.json) preserves full-precision originals and calculations. Percentages use original recorded values as denominators. No current raw discrepancy or adjusted value exceeds the user’s 5% review threshold. Any future point over that threshold is blocked pending review.

Measurement displays, chart axes, cursor labels, tooltips, source-peak text and comparison CSV values round to three significant figures. Rider and gear inputs were subsequently simplified to whole pounds; bike-weight input still accepts decimals and rounds its display when editing ends. Calculations and stored weights retain their accepted precision. Model names, years, counts and original publisher chart images retain their identifying content.
