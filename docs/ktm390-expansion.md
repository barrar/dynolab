# KTM 390 additional dyno and tune research

Research checked November 2, 2026. Import data: `docs/ktm390-expansion.json`.

The deliverable contains **one additional independent stock test**, **one additional chart-ready intake/exhaust/fueling tune**, and **two further primary-documented intake/exhaust/ECU packages without public verified RPM data**. A fifth ECUWEST record retains its original chart as source-only evidence because its hardware and RPM indexing are unresolved. No peak-only source has been converted into a fabricated curve.

All these records belong to the older **373 cc engine generation**. None is a direct 399 cc / Euro5b / 2025+ Adventure R dyno test. The bike IDs distinguish the older Adventure and Duke from the existing app’s newer KTM 390 entry.

## Imported curves

### 2020 KTM 390 Adventure, stock — Cycle World

- [Original independent test](https://www.cycleworld.com/story/bikes/how-much-power-does-the-2020-ktm-390-adventure-make/), April 15, 2020, in-house Dynojet 250i.
- [Original chart image](https://cloudfront-us-east-1.images.arcpublishing.com/octane/UNS3LRGCFFCU3JIQTSNQ7MYZ6U.jpg).
- Local chart: `assets/charts/ktm-research-stock-2020-adventure.jpg`.
- Printed peaks: **37.46 hp at 8,970 RPM; 23.23 lb-ft / 31.50 N·m at 6,990 RPM**. Rear-wheel test.
- Approximate chart trace sampled over 2,500–10,000 RPM. One-decimal power samples; the power peak follows the printed peak rounded to one decimal. Torque is derived using `N·m = hp × 7120.9092 / RPM`.
- [Dirt Rider’s same-year/model full test](https://www.dirtrider.com/story/tests/2020-ktm-390-adventure-review/) supplies **387 lb measured wet with a full fuel load**. This is a model reference weight, not an assertion that it is the identical Cycle World dyno specimen.

### KTM 390 Duke, Rottweiler / Dynojet Power Commander V

- [Original vendor map and full fitted-hardware list](https://shop.rottweilerperformance.com/duke-390-all-rott-perf-airbox-lid-de-cat-mid-pipe-muffler-db-insert-performance-map/).
- [Original chart image](https://cdn11.bigcommerce.com/s-xk32d/images/stencil/1280x1280/products/931/6174/Screenshot_2019-05-21_17.55.47__44386.1558486816.png?c=2).
- Local chart: `assets/charts/ktm-research-rottweiler-duke390.png`.
- **Verified combination:** PCV piggyback fuel controller and Rottweiler in-house map, Rottweiler airbox lid, Arrow decat mid-pipe, open muffler with dB insert. Source says the map was built on its in-house dyno. Chart uses SAE correction and smoothing 5.
- The imported **green full-hardware mapped power trace** is approximately 42.6 hp at its graphical maximum. It has **no printed maximum**. The chart’s printed **42.41 hp is blue**, which retains the stock airbox lid with custom mapping; printed **39.71 hp is red**, which retains the stock airbox lid and stock mapping. All traces already have the decat and muffler. **Red is not a completely stock motorcycle.**
- Approximate trace samples 3,500–10,100 RPM; torque derived from power. This is a rear-wheel chassis-dyno power trace, not an engine-output estimate.
- Exact motorcycle model year and test date are absent. The image upload/filename dates to May 2019, establishing older 373 cc era provenance; the shop’s “ALL” product title is not proof of 2025+ compatibility.
- [Rider’s 2015 Duke road test](https://ridermagazine.com/2015-ktm-390-duke-road-test-review/) lists **340 lb wet**, used only as an explicitly labeled older Duke reference. Actual tuned build weight and exact model year are unknown. No dry-to-wet conversion or exhaust weight saving was invented.

## Source-only documented combinations

### BR-Performance Stage 2, 2015–2023 Duke 390

- [Original Stage 2 product page](https://www.br-performance.lu/en-lu/chiptuning/3817-bikes-quad/4169-ktm/11331-390/11913-2015-2023/14393-390-duke/?stage=19391).
- **Verified combination:** full decat exhaust, sports air filter, Stage 2 engine remap.
- Vendor lists indicative 44 → 50 hp and 39 → 45 N·m. It explicitly says actual results vary and are measured for the customer after individual tuning.
- No public RPM graph, run date, exact tested motorcycle, correction standard or wheel/crank basis supplied. `points: []`. Values are labeled **vendor indications**, never measured curve data.

### Mantra Racing Stage II Sport Plus, 2016 KTM 390

- [Manufacturer demonstration](https://www.youtube.com/watch?v=PMRd0UnwzZw), Mantra Racing channel.
- Manufacturer description identifies **2016 KTM 390**, Stage II Sport Plus ECU, **TBM air filter, de-restrictor plate and Mantra full exhaust system**. It describes standard gearing/wheels/tires and no weight reduction except mirrors.
- The description offers dyno graphs by request. An original accessible manufacturer RPM chart could not be recovered. Secondary articles reproduce horsepower figures/graphs, but no original primary chart with verified wheel/crank basis was available.
- `points: []`; no secondary peak numbers imported and no estimated curve generated. Hardware-qualified evidence only.

## ECUWEST chart retained, not plotted

- [Original pre-2017 ECU remapping page](https://www.ecuwest.com.au/ktm-rc390-duke-ecu-remapping/).
- [Original chart download](https://ecuwest.com.au/wp-content/uploads/2018/08/2015-KTM-RC390.jpg). The server sends a BMP under a `.jpg` URL; local file is losslessly converted to `assets/charts/ktm-research-ecuwest-2015-rc390.png` for Flutter compatibility.
- Actual report identifies **2016 KTM 390 Duke**, March 15–16, 2016, Mainline DynoLog chassis dyno, corrected SAE J607.
- Main report prints before **37.1 hp / 30 N·m**, after **40.5 hp / 34 N·m**. The lower panel is labeled **estimated Dynojet power** and is not treated as the main measured output.
- Page text discusses free-flow exhausts and airbox mods, while the particular chart header says **STD** for exhaust/induction/manifolds. Therefore this record is **not counted as a verified intake/exhaust combination**.
- Main x-axis is road speed. The secondary tacho RPM scale places the tuned graphical power maximum around 9,900 RPM, whereas its printed peak metadata says 9,346 RPM. The secondary scale may correspond to a different run; it cannot safely index the tuned curve. `points: []` rather than misleading RPM hover data.

## Additional original chart retained for reference

- [Rottweiler’s 2015 RC390 PCV map](https://shop.rottweilerperformance.com/rc390-all-rott-perf-airbox-lid-decat-open-muffler-power-map/) explicitly describes a 2015 RC390 with opened airbox and Arrow GP full exhaust.
- [Original Dynojet chart](https://cdn11.bigcommerce.com/s-xk32d/images/stencil/1280x1280/products/316/2031/Complete_before_and_after__48997.1478453592.jpg?c=2), local `assets/charts/ktm-research-rottweiler-2015-rc390.jpg`.
- Not imported as a duplicate tune brand or used as an independent fully stock test. It confirms a second exact-model primary use of the Rottweiler PCV intake/exhaust combination.

## Data integrity

- `measurementBasis` is explicit on every record. Source-only vendor figures do not acquire a rear-wheel label by default.
- `hasCurve`, `sourceOnly` and `hardwareQualified` are explicit; a documented combination is not automatically a measured comparison.
- Chart samples are approximate image readings and are not raw dyno data. No curves are extrapolated beyond their sampled range. Peak metadata is kept distinct.
- Every supplied weight is sourced as wet; tuned-build weights are explicitly unknown where applicable. No unverified dry-to-wet conversion is present.
- No main application files were edited by this research task.
