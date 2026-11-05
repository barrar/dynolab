# Torque and horsepower consistency audit

**Applied to derived app curves; original samples preserved.** 807 source points across 56 curves; 0 points and 0 interpolated curves exceed the conservative 5.00% review threshold.

For each source point, convert recorded horsepower to torque using its RPM, average that result with the recorded torque, and derive horsepower from the average. Between samples, interpolate torque and calculate horsepower from torque and RPM. No original source samples or publisher charts are overwritten.

Percent changes use the recorded torque or horsepower as the baseline. The review gate also checks the raw torque discrepancy before averaging. All table measurements use three significant figures. The JSON preserves full precision. Interpolated HP differences compare with the previous linear-HP curve at 1 RPM intervals.

## Changes by curve

Maximum torque adjustments are signed; raw discrepancies and source-point HP changes are absolute maxima. Tiny differences can result from the source dataset rounding previously derived torque.

| Bike / run | Samples | Max raw torque discrepancy | Max torque adjustment | RPM of torque adjustment | Max source-point HP change | Max HP change including interpolation |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Honda CRF300L / Stock | 18 | 1.00% | +0.501% | 10,400 | 0.496% | -0.530% |
| Honda CRF300L / 550 Performance · Stage 1.0 | 18 | 0.758% | -0.379% | 4,500 | 0.382% | +0.382% |
| KTM 390 / Stock · Euro 5b reference | 18 | 1.65e-14% | +1.33e-14% | 9,500 | 0.00% | -0.407% |
| KTM 390 / COOBER LM ECU + DeCat | 18 | 2.13e-14% | +2.13e-14% | 7,500 | 0.00% | -0.267% |
| BMW R 1300 / Stock · Cycle World (2025) | 16 | 0.00440% | +0.00220% | 2,500 | 0.00220% | +0.186% |
| BMW F 900 / Stock · LeoVince / Dynojet (2024–25) | 12 | 0.00537% | -0.00268% | 5,000 | 0.00268% | -0.166% |
| Ducati DesertX 937 / Stock · Cycle World (2023) | 17 | 0.00729% | -0.00365% | 3,000 | 0.00365% | -0.567% |
| Honda Africa Twin 1100 / Stock · Rider / Jett Tuning (2020) | 13 | 0.00534% | +0.00267% | 5,000 | 0.00267% | -0.743% |
| Suzuki V-Strom 800 / Stock · Cycle World (2023) | 17 | 0.00897% | +0.00449% | 2,000 | 0.00449% | -0.573% |
| Yamaha Ténéré 700 / Stock · Cycle World (2025) | 16 | 0.0100% | +0.00500% | 3,000 | 0.00500% | -0.993% |
| KTM 890 / Stock · Cycle World (2023) | 15 | 0.00704% | +0.00352% | 3,000 | 0.00352% | -0.595% |
| Triumph Tiger 900 · 2020–23 / Stock · Rider / Jett Tuning (2020) | 16 | 0.00688% | -0.00344% | 2,500 | 0.00344% | -0.190% |
| Royal Enfield Himalayan 450 / Stock · Cycle World (2024) | 14 | 0.0131% | +0.00657% | 7,500 | 0.00657% | -0.723% |
| Honda CRF450RL / Stock · 2023 Dirt Rider dyno | 16 | 0.00153% | +7.67e-4% | 4,500 | 7.67e-4% | -0.351% |
| KTM 350 EXC-F / Stock · 2019 Dirt Rider dyno | 19 | 0.00186% | +9.30e-4% | 3,000 | 9.30e-4% | -0.215% |
| KTM 500 EXC-F / Stock · 2023 Dirt Rider dyno | 15 | 0.00146% | +7.30e-4% | 9,500 | 7.30e-4% | -0.467% |
| KTM 690 / Stock · 2019 Cycle World dyno | 16 | 0.00102% | +5.08e-4% | 4,000 | 5.08e-4% | -0.943% |
| Husqvarna 701 / Stock · 2021 Enduro LR reference | 15 | 0.00107% | +5.33e-4% | 4,000 | 5.33e-4% | -0.353% |
| Suzuki DR-Z4 / Stock · 2025 Cycle World dyno | 17 | 0.00255% | -0.00128% | 2,000 | 0.00128% | -0.613% |
| Suzuki DR650 / Stock · 2022 Dirt Rider dyno | 12 | 0.00145% | +7.25e-4% | 7,500 | 7.25e-4% | -0.843% |
| Kawasaki KLX300 / Stock · 2021 Dirt Rider dyno | 17 | 0.00297% | -0.00148% | 2,500 | 0.00148% | -0.458% |
| Honda CRF250F / Stock · 2022 Dirt Rider dyno | 14 | 0.00309% | -0.00154% | 9,000 | 0.00154% | -0.298% |
| Honda CBR650R / Stock · 2019 Cycle World dyno | 23 | 0.00107% | +5.33e-4% | 2,500 | 5.33e-4% | -0.384% |
| KTM 390 · 373 cc / Stock · 2020 Adventure · Cycle World | 17 | 0.00188% | +9.38e-4% | 10,000 | 9.38e-4% | -0.273% |
| KTM 390 · 373 cc / Rottweiler / Dynojet PCV · airbox lid + decat + muffler | 16 | 0.00175% | +8.77e-4% | 4,000 | 8.77e-4% | -0.275% |
| Aprilia Tuareg 660 / Stock · 2022 Cycle World test | 18 | 0.00% | 0.00% | 2,500 | 1.48e-14% | -0.265% |
| KTM 790 / Stock · 2020 Adventure R test | 15 | 0.00% | 0.00% | 2,500 | 2.10e-14% | -2.08% |
| Kawasaki KLR650 / Stock · 2022 fuel-injected test | 9 | 0.00% | 0.00% | 2,500 | 2.12e-14% | -0.314% |
| Suzuki DR-Z400 / Stock · 2022 Dirt Rider test | 14 | 0.00% | 0.00% | 3,000 | 0.00% | -0.669% |
| Honda CRF300L / 550 · Stage 1.5 · 91 AKI | 17 | 0.00% | 0.00% | 2,500 | 1.42e-14% | -0.350% |
| BMW R 1300 / Stock · GS · BT Moto Stage 1 baseline | 10 | 0.00% | 0.00% | 3,500 | 1.43e-14% | +0.232% |
| BMW R 1300 / BT Moto · Stage 1 · 93 AKI | 10 | 0.00% | 0.00% | 3,500 | 2.07e-14% | +0.237% |
| BMW R 1300 / Stock · GS · BT Moto Stage 2 baseline | 11 | 0.00% | 0.00% | 3,500 | 2.19e-14% | +0.234% |
| BMW R 1300 / BT Moto · Stage 2 + velocity stacks | 11 | 0.00% | 0.00% | 3,500 | 0.00% | -0.329% |
| BMW F 900 / Stock · 2024 GS · RS2E baseline | 16 | 0.00% | 0.00% | 2,000 | 1.92e-14% | -0.701% |
| BMW F 900 / RS2E V2026 · stock exhaust | 16 | 0.00% | 0.00% | 2,000 | 1.75e-14% | -0.845% |
| BMW F 900 / RS2E V2026 · race exhaust | 16 | 0.00% | 0.00% | 2,000 | 2.04e-14% | -0.810% |
| KTM 890 / Stock · Adventure R · BT Moto | 14 | 0.00% | 0.00% | 2,500 | 1.31e-14% | -1.03% |
| KTM 890 / BT Moto · Adventure R · Stage 1 · 91 AKI | 14 | 0.00% | 0.00% | 2,500 | 2.04e-14% | -1.04% |
| KTM 890 / Stock · 2023 Duke · BT Moto | 14 | 0.00% | 0.00% | 3,500 | 1.57e-14% | +0.321% |
| KTM 890 / BT Moto · 2023 Duke · Stage 1 · 93 AKI | 14 | 0.00% | 0.00% | 3,500 | 2.13e-14% | +0.114% |
| Ducati DesertX 937 / Stock · 2023 DesertX · BT Moto | 15 | 0.00% | 0.00% | 2,500 | 1.70e-14% | -0.404% |
| Ducati DesertX 937 / BT Moto · Stage 1 · DesertX 937 | 15 | 0.00% | 0.00% | 2,500 | 1.61e-14% | -0.628% |
| Honda Africa Twin 1100 / Stock · 2024 Africa Twin · 91 AKI | 12 | 0.00% | 0.00% | 2,500 | 1.51e-14% | -0.224% |
| Honda Africa Twin 1100 / BT Moto · Stage 1 · 91 AKI | 12 | 0.00% | 0.00% | 2,500 | 1.50e-14% | -0.221% |
| Honda Africa Twin 1100 / Stock · 2024 Africa Twin · 93 AKI | 11 | 0.00% | 0.00% | 2,500 | 1.39e-14% | -0.811% |
| Honda Africa Twin 1100 / BT Moto · Stage 1 · 93 AKI | 11 | 0.00% | 0.00% | 2,500 | 0.00% | -0.341% |
| KTM 690 / Stock · 2023 SMC R · BT Moto | 10 | 0.00% | 0.00% | 3,000 | 2.24e-14% | -0.352% |
| KTM 690 / BT Moto · 2023 SMC R · Stage 1 | 11 | 0.00% | 0.00% | 3,000 | 0.00% | -0.355% |
| KTM 690 / OEM map + Remus · 2022 Enduro R | 10 | 0.00% | 0.00% | 3,000 | 1.51e-14% | -0.253% |
| KTM 690 / Rapid Bike Racing + Remus · 2022 Enduro R | 10 | 0.00% | 0.00% | 3,000 | 0.00% | -0.427% |
| Honda CRF450RL / Stock · CRF450L/RL · 550 baseline | 13 | 0.00% | 0.00% | 3,500 | 2.70e-14% | -0.195% |
| Honda CRF450RL / 550 · Stage 1.0 · full exhaust | 14 | 0.00% | 0.00% | 3,500 | 1.61e-14% | +0.176% |
| Honda CRF450RL / 550 · Stock Improved · stock exhaust | 14 | 0.00% | 0.00% | 3,500 | 2.49e-14% | -0.278% |
| Husqvarna 701 / Stock · 701 · body/year unspecified | 12 | 0.00% | 0.00% | 2,500 | 1.13e-14% | -0.389% |
| Husqvarna 701 / BT Moto · 701 Stage 1 · body/year unspecified | 13 | 0.00% | 0.00% | 2,500 | 1.98e-14% | -0.450% |

## Review gate

No changes exceed 5.00%, including the raw torque discrepancies before averaging. No additional approval was required.

The [per-point CSV](dyno-consistency-points.csv) includes every original value, horsepower-implied torque, averaged torque, calculated horsepower, and signed percentage change. The [JSON](dyno-consistency-audit.json) retains full precision. Rounding the displayed measurements can conceal very small adjustments.

## Display and weight normalization

All app measurements and comparison CSV values display three significant figures. Model names, model years, collection counts, and the original published chart images retain their identifying content. Calculations and saved weights keep full precision.

The single **Per 100 lb** switch applies `100 × horsepower / total lb` and `100 × torque / total lb` to both metrics. Total weight includes the optional shared rider and gear weights. For example, 0.0700 hp/lb becomes 7.00 hp/100 lb.
