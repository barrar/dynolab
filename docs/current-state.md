# Current implementation and continuation context

Updated November 5, 2026. The catalog release was published to `moto-dynolab` at <https://moto.bendtrailmaps.com/> on November 5 at 2026-11-05T21:21:07.139153Z. Cloudflare confirmed version `f1049da7-58d8-4e82-b865-5b1b797511bb` at 100% traffic and the existing custom domain enabled. Publication used the authenticated Cloudflare connector because the Wrangler CLI login had expired. The release includes 92 public build files, with 32 changed assets uploaded; local `.DS_Store` and `.last_build_id` files were excluded. No public-browser verification was performed. Research findings retain their November 3 review date.

## Completed catalog work

The bundled catalog has **28 families, 76 source records, 56 drawable curves and 807 original sample points**. The importer reports 72 records / 52 curves / 26 generated families; the four original Honda/KTM configurations and two families are added by `lib/dyno_data.dart`. Twenty records remain source-only.

Five added families are Aprilia Tuareg 660, KTM 790, Kawasaki KLR650, Suzuki DR-Z400 and Honda CB500X. CB500X remains source-only. The latest research adds 30 upgrade records, 15 of them plotted tuned runs, plus associated baselines. Across older and newer inputs there are 34 upgrade records; do not confuse the latest additions with the catalog total. The sampling ledger covers 31 later curves / 402 points; the remaining 25 curves / 405 points predate that ledger.

Shared-engine model variants appear under one family where appropriate. KTM 890 has Adventure, Adventure R and Duke R weight choices. Tested body/year, hardware and calibration stay attached to each dyno configuration. The older 373 cc KTM 390 family remains separate from the 399 cc Euro 5b family. Historical shared-link IDs and preset masses are preserved.

The library includes **Adventure · 10**, **Dual sport · 10**, **More bikes**, and **Upgrades**, plus a research outcome for every family. Tuned runs with appropriate linked baselines offer **Add matching stock run** using the same selected mass. The original Honda/KTM comparison shortcuts select their explicit original pairs.

## Where to work next

| Need | Entry point |
| --- | --- |
| Repeat the catalog/tune task | [Maintenance runbook](catalog-maintenance-runbook.md) |
| See every family's research result and accepted/rejected evidence | [November 3 research report](tuning-research-2026-11-03.md), [`tune-coverage.json`](tune-coverage.json) |
| Correct a source, curve, weight or grouping | [Data workflow](data-workflow.md), research JSON and chart assets |
| Find code/state ownership | [Architecture](architecture.md) |
| Set up the SDK or preview | [Development](development.md) |
| Preserve compact links | [Sharing contract](compact-sharing.md), `lib/share_catalog.dart` |
| Publish an authorized release | [Deployment](deployment.md) |

The research target was up to two evidenced aftermarket setups per family, accepting fewer. Missing curves are documented evidence gaps rather than implementation bugs. Prioritize primary-source before/after charts, exact generation/calibration identity and readable RPM axes. Do not turn existing peak-only, ambiguous or unavailable evidence into a synthetic curve to fill a quota. The 701 BT Moto run remains unspecified body/year; it is not a 2021 Enduro LR-specific measurement.

## Environment and verification

The user authorized GitHub publication on November 5, 2026, following a repository secret scan. The project is published at <https://github.com/barrar/dynolab>; this checkout originally had no Git metadata, so its history starts with that publication. Later deployments and pushes require the user's instruction. The local SDK was upgraded to Flutter 3.47.9 stable / Dart 3.13.7 at `/Users/jeremiah/projects/flutter`, replacing the project's temporary recovery SDK. The incomplete installation was preserved at `/Users/jeremiah/projects/flutter-incomplete-backup-20261105`. The SDK upgrade and package updates were validated locally before publication. Download work under `/private/tmp/assetcapture-research` and temporary harvesting scripts are historical scratch files, not generation dependencies. All maintained inputs are under this project.

The completed implementation passed Flutter analysis, all 49 tests, and the Wasm release build. The numerical audit covers 807 points / 56 curves with zero source-point or intermediate review flags over 5%. The added sampling replay checks all 31 ledger curves / 402 points. Refer to the commands in the runbook and rerun them after changes; these counts are a dated result, not a permanent expectation.

The November 5 SDK upgrade was separately validated on Flutter 3.47.9 / Dart 3.13.7: analysis clean, all 49 tests passing, WebAssembly release build successful, and the local debug app rendering with working normalization controls and no browser console errors. The development server uses <http://127.0.0.1:52741/>. Seven packages were upgraded: clock 1.1.3, matcher 0.12.20, meta 1.19.0, stack_trace 1.12.2, test_api 0.7.12, vector_math 2.4.4 and web 1.1.2. All direct dependencies are current; material_color_utilities 0.13.0 and test_api 0.7.12 are the newest versions accepted by this Flutter SDK's constraints.

The November 5 completion also confirmed unchanged formatted output after regeneration, checked 136 local documentation links plus anchors/JSON examples/whitespace, and verified that the sampling helper rejects altered power, incorrect X calibration, unknown/duplicate configuration references, out-of-canvas pixels and missing expansion input. Those rejection checks used isolated temporary copies of the evidence.

Local browser verification covers the KTM 890 grouped selector, model mass changing independently of tested run identity, library upgrade/research views and source/baseline controls. The user subsequently authorized the publication recorded above. Cloudflare confirmed the deployment and domain binding; retain the existing instruction against repeatedly loading the public site during deployment work.

General opportunities include a pinned SDK/CI, original dyno-file imports where available, image-assisted digitization with visual review, more primary-source coverage, and broader automated browser checks. They are future improvements, not unfinished requirements of this catalog/documentation task.
