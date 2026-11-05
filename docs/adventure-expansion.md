# Adventure-bike dyno expansion

Reviewed November 2, 2026. These nine entries plus the existing KTM 390 Adventure weight scenario form an **editorial ten-bike adventure selection** for the U.S. market. This is a useful spread of smaller, middleweight, and large touring adventure choices, not a sales ranking or a claim of objective superiority.

Every new entry has a real published stock dyno chart bundled under `assets/charts/adv-*`. Horsepower was sampled from the actual red stock power trace, using each chart's displayed RPM and power axes. Torque values are derived from those horsepower samples as `N·m = hp × 7120.9092 / RPM`. No curve was generated from peak specifications alone. Samples are approximate, typically spaced 500 RPM apart; printed peak values are recorded separately. Interpolation and source-domain limits belong to the app.

| Entry | Actual source/test | Weight used | Notes |
| --- | --- | --- | --- |
| BMW R 1300 GS | [Cycle World 2025 test](https://www.cycleworld.com/motorcycle-reviews/bmw-r-1300-gs-review/) | 566 lb measured wet | Equipped Triple Black test motorcycle. Do not substitute BMW's lighter 523 lb standard-equipment claim without relabeling. |
| BMW F 900 GS | [Official LeoVince 2024–25 stock chart PDF](https://static.leovince.com/products/powerdiagrams/GP%20-%2015610U%20%28F900GS%29.pdf) | 482 lb claimed wet | Only the red `STOCK.wp8` trace is used. SAE correction, smoothing 5. Weight is a manufacturer reference, not a measured mass of this dyno motorcycle. |
| Ducati DesertX 937 | [Cycle World 2023 test](https://www.cycleworld.com/bikes/ducati-desertx-dyno-test-2023/) | 518 lb measured wet | Crashbars, aluminum hand guards and skid plate fitted. 937 cc Testastretta generation, not the new 2026 890 cc V2. |
| Honda Africa Twin 1100 Adventure Sports ES | [Rider / Jett Tuning 2020 test](https://ridermagazine.com/2020-honda-africa-twin-crf1100l-adventure-sports-es-road-test-review/) | 560 lb as tested | Manual Adventure Sports ES with Honda panniers. Explicit older test; does not claim to measure a 2024+ or DCT model. |
| Suzuki V-Strom 800DE | [Cycle World 2023 test](https://www.cycleworld.com/bikes/suzuki-v-strom-800de-dyno-test-2023/) | 507 lb measured wet | 776 cc stock parallel twin. |
| Yamaha Ténéré 700 | [Cycle World 2025 test](https://www.cycleworld.com/bikes/yamaha-tenere-700-dyno-test-2025/) | 473 lb measured wet | Accessory crashbars fitted. This is the updated 2025 bike, not a substituted MT-07 curve. |
| KTM 890 Adventure R | [Cycle World 2023 test](https://www.cycleworld.com/bikes/ktm-890-adventure-r-dyno-test-2023/) | 477 lb measured wet | Stock 889 cc LC8c; source chart prints 93.28 hp and 64.37 lb-ft peaks. |
| Triumph Tiger 900 Rally Pro (2020–23) | [Rider / Jett Tuning 2020 test](https://ridermagazine.com/2020-triumph-tiger-900-rally-pro-tour-test-review/) | 476 lb wet | The 2024 engine gained power; the older measured curve must stay labeled as an older generation. |
| Royal Enfield Himalayan 450 | [Cycle World 2024 test](https://www.cycleworld.com/bikes/royal-enfield-himalayan-450-dyno-test-2024/) | 441 lb measured wet | Stock 452 cc Sherpa single. |

## U.S. availability references

The JSON records contain an OEM U.S. model/family URL for each entry. Availability is verified for the model families; the precise tested older model year is preserved in every chart configuration. A current U.S. lineup page is not proof that an old dyno curve represents a redesigned current engine.

- [BMW R 1300 GS](https://www.bmwmotorcycles.com/en/models/adventure/r1300gs.html) and [F 900 GS](https://www.bmwmotorcycles.com/en/models/adventure/f900gs.html).
- [Ducati U.S. DesertX 937 page](https://www.ducati.com/us/en/bikes/desertx/desertx-937).
- [Honda U.S. Africa Twin](https://powersports.honda.com/motorcycle/adventure/africa-twin).
- [Suzuki U.S. 2026 V-Strom 800DE](https://suzukicycles.com/adventure/2026/v-strom-800de).
- [Yamaha U.S. Ténéré 700](https://yamahamotorsports.com/models/tenere-700).
- [KTM U.S. adventure lineup](https://www.ktm.com/en-us/models/adventure.html), including the 890 Adventure R.
- [Triumph U.S. Tiger 900 model range](https://www.triumphmotorcycles.com/motorcycles/adventure/tiger-900/models).
- [Royal Enfield U.S. model list](https://www.royalenfield.com/us/en/motorcycles/classic-models/), including the Himalayan 450.

## Visual and numerical checks

The JPEG/PNG images were opened and visually inspected before sampling. The F 900 GS PDF was rendered to PNG before sampling. Calibration uses chart grid values and tick locations, not a fitted idealized curve. Samples are rounded to 0.1 hp; image resolution, line thickness and manual tick calibration mean the sampled maxima can differ slightly from printed peak summaries. No original Dynojet `.drf` or similar run file was obtained. Dyno correction, tires, test conditions and accessory weights differ across publishers; this is an exploratory comparison.

The BMW R 1300 GS article’s full body/chart was retrieved from the publisher’s public Arc CDN when its canonical page returned a shortened body. Its original chart remains on the publisher’s image CDN, and the canonical article URL is retained for attribution.

Only the red stock trace in LeoVince’s F 900 GS chart was sampled; its aftermarket exhaust traces were excluded. The chart’s tested market is not stated, so it is not a guaranteed exact U.S.-emissions calibration match.
