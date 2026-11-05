# Dual-sport and requested Honda expansion

Prepared 2026-11-02. This is an editorial selection of familiar, U.S.-available dual-sport families, not a claim about model-level sales rankings. Historical tests are retained under their actual test years; current availability does not make an older curve representative of the latest model.

The ten-family selection is Honda CRF300L, Kawasaki KLX300, Suzuki DR-Z4S, Honda CRF450RL, KTM 500 EXC-F, KTM 350 EXC-F, Suzuki DR650S, KTM 690 Enduro R, Husqvarna 701 Enduro, and KTM 390 Enduro R. The app's existing CRF300L and KTM 390 references cover two families. This expansion supplies the remaining eight. The KTM 390 Enduro is a weight/model preset using the separately labeled 390 engine curves, not an independently tested Enduro dyno in this file.

The explicitly requested CRF250F, CRF300F and CBR650R are additional models. The F Hondas are off-road trail motorcycles and the CBR650R is a road sport motorcycle; none counts toward the dual-sport ten.

## Files and sampling

- `docs/dual-sport-expansion.json`: 11 records, 10 chart-ready configurations and one source-only CRF300F record.
- `assets/charts/ds-*.jpg`: ten original publisher chart images, with original page and image URLs retained in the JSON.
- 164 horsepower samples in total. Samples are approximate readings from actual chart traces, generally spaced 500 RPM apart with a sample near each printed horsepower peak. They are not reconstructed from peak specifications.
- Torque is derived from each sampled wheel-horsepower point with `N·m = hp × 7120.9092 / RPM`. Linear interpolation between samples should be disclosed in the app. Reported publisher peak numbers remain separate and can differ slightly from sampled peaks.
- All ten usable charts are rear-wheel chassis-dyno tests. Different operators, motorcycles, tires, correction factors and test days prevent treating them as a controlled comparison.
- The largest domain is the CBR650R at 12,500 RPM; the KTM 350 trace reaches 11,500 RPM. Do not crop all curves at 10,500 RPM.

## Measured configurations

| Test | Printed wheel horsepower / torque | Default weight | Original test and weight reference |
| --- | --- | --- | --- |
| 2023 Honda CRF450RL | 38.0 hp at 7,500 RPM / 27.8 lb-ft at 6,400 RPM | 293 lb measured wet | [Dyno](https://www.dirtrider.com/tests/honda-crf450rl-dyno-test-2023/), [review/weight](https://www.dirtrider.com/tests/honda-crf450rl-review/) |
| 2019 KTM 350 EXC-F | 34.74 hp at 8,840 RPM / 22.43 lb-ft at 7,250 RPM | 255 lb measured ready to ride | [Dyno](https://www.dirtrider.com/2019-ktm-350-exc-f-dyno-test/), [comparison/weight](https://www.dirtrider.com/2019-ktm-350-exc-f-vs-2019-ktm-500-exc-f-comparison-review/) |
| 2023 KTM 500 EXC-F | 40.5 hp at 8,200 RPM / 28.6 lb-ft at 7,000 RPM | 255 lb measured wet | [Dyno](https://www.dirtrider.com/tests/ktm-500-exc-f-dyno-test-2023/), [technical information/weight](https://www.dirtrider.com/dirt-bikes/ktm-500-exc-f-technical-information-2023/) |
| 2019 KTM 690 Enduro R | 59.15 hp at 8,230 RPM / 43.36 lb-ft at 6,810 RPM | 346 lb measured wet | [Dyno](https://www.cycleworld.com/how-much-power-does-2019-ktm-690-enduro-r-make/), [review/weight](https://www.dirtrider.com/ktm-690-enduro-r-review/) |
| 2021 Husqvarna 701 Enduro LR reference | 60.31 hp at 8,510 RPM / 44.03 lb-ft at 6,740 RPM | 388 lb measured wet, LR tanks full | [Dyno](https://www.cycleworld.com/story/bikes/2021-husqvarna-701-enduro-lr-dyno-test/), [comparison/weight](https://www.dirtrider.com/story/dirt-bike-tests-and-reviews/big-dual-sport-motorcycle-vs-adventure-bike-comparison-test/) |
| 2025 Suzuki DR-Z4S | 33.50 hp at 8,120 RPM / 23.87 lb-ft at 6,610 RPM | 333 lb published curb | [Dyno and weight](https://www.cycleworld.com/bikes/suzuki-dr-z4s-dyno-test-2025/) |
| 2022 Suzuki DR650S | 35.1 hp at 6,200 RPM / 32.2 lb-ft at 4,500 RPM | 369 lb measured wet | [Dyno and weight](https://www.dirtrider.com/story/tests/2022-suzuki-dr650s-dyno-test/) |
| 2021 Kawasaki KLX300 | 23.4 hp at 8,100 RPM / 15.4 lb-ft at 8,000 RPM | 302 lb measured wet | [Dyno](https://www.dirtrider.com/story/tests/2021-kawasaki-klx300-dyno-test/), [review/weight](https://www.dirtrider.com/story/tests/2021-kawasaki-klx300-review/) |
| 2022 Honda CRF250F | 20.1 hp at 7,500 RPM / 15.5 lb-ft at 6,000 RPM | 264 lb measured wet | [Dyno](https://www.dirtrider.com/story/tests/2022-honda-crf250f-dyno-test/), [review/weight](https://www.dirtrider.com/story/tests/honda-crf250f-review-2022/) |
| 2019 Honda CBR650R | 80.10 hp at 10,950 RPM / 41.73 lb-ft at 8,170 RPM | 455 lb measured fully fueled | [Dyno and weight](https://www.cycleworld.com/how-much-power-does-2019-honda-cbr650r-make/) |

## Model-year and weight caveats

The Husqvarna curve is specifically the **2021 701 Enduro LR**, a historical platform reference for the 701 family. Its 388 lb full-fuel weight belongs to the large-tank LR, not the current standard 701 Enduro. The associated comparison labels its LR as a 2020 model, whereas the dyno article and chart label the test 2021; this discrepancy is recorded in the JSON. The 2026 standard 701 has an updated engine and must not inherit this output or mass as a current-bike measurement.

The KTM 350 uses the 2019 test, the KTM 500 the 2023 test before the 2024 redesign, and the 690 the 2019 test before later updates. Each is labeled accordingly. All default weights are wet/curb/full-fuel references; no dry figure is silently treated as wet weight. A user's selected model weight can be applied to a historical engine curve, but the app should make that combination visible.

Current U.S. family availability links are stored separately from dyno sources in every record. The CRF250F is retained as a historical U.S. model; the CRF300F is its current larger trail-bike successor.

## CRF300F source-only record

The [2026 U.S. Honda CRF300F](https://powersports.honda.com/motorcycle/trail/crf300f/2026/crf300f) is a real, separate model, not the liquid-cooled CRF300L. Its [official U.S. specifications PDF](https://powersports.honda.com/api/custom/downloads/specs?category=trail&segment=motorcycle&trim=CRF300FT&year=2026) lists 293 cc, a six-speed transmission, and **271 lb curb weight including fluids and a full tank**. Honda's product-page displacement presentation can round to 294 cc; this record follows the specification PDF.

A usable full measured U.S.-model dyno trace was not located after focused searches for independent and manufacturer charts. The entry therefore has an empty points array and a source-only status. International claimed peak figures and the CRF250F trace are not substituted. The [RevZilla U.S. first-ride review](https://www.revzilla.com/common-tread/2026-honda-crf300f-first-ride-review) also notes that Honda does not publish U.S. horsepower and torque figures. The bike can be shown in the library with its sources and weight, while its graph action remains disabled until a verified curve is available.
