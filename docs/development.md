# Developing DynoLab

## Toolchain

The application targets **desktop and mobile websites only**. This checkout has no iOS, Android, macOS, or Windows application targets. Do not regenerate native platform scaffolding to make a web change.

The development SDK inspected for these guides is Flutter **3.44.0 stable**, Dart **3.12.0**. `pubspec.yaml` requires Dart `^3.12.0`. Runtime dependencies are Flutter and `package:web`; development dependencies are `flutter_test` and `flutter_lints`. Python 3 is used for research import and the local release preview. Deployment additionally uses Node/npm and Wrangler 4.

On a normal machine:

```sh
flutter --version
dart --version
flutter pub get
```

Keep `pubspec.lock` with the application source so dependency resolution is reproducible. Review SDK or dependency upgrades as separate changes where practical. There is no checked-in Flutter version manager configuration, CI workflow, or pinned Wrangler package yet.

On the original Mac, `/Users/jeremiah/projects/flutter` was missing SDK executables. Development used an isolated recovery copy at `/private/tmp/assetcapture-flutter-sdk`. If it still exists, its binaries can be used explicitly:

```sh
/private/tmp/assetcapture-flutter-sdk/bin/flutter --version
/private/tmp/assetcapture-flutter-sdk/bin/dart --version
```

This is not a project setup step to reproduce on another machine. Install or locate a complete Flutter SDK if the temporary copy is gone. Do not replace the original SDK working tree blindly.

## Run and preview

For development:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 52741
```

Open <http://127.0.0.1:52741/>. Keep the server running while testing. Check whether the port already has a running preview before starting another process; use another port instead of terminating an unrelated service.

For the production-style Wasm release:

```sh
flutter build web --wasm --release --no-web-resources-cdn
./scripts/serve.sh
```

Or use `PORT=52742 ./scripts/serve.sh` for another local port. Rebuild after source or asset changes; the release server does not hot reload. Then reload the browser. It reads files from `build/web` and binds only to `127.0.0.1`.

`scripts/serve.py` supplies navigation fallback to `index.html`, including extensionless state paths, while missing non-navigation assets remain 404s. A standard Python file server is insufficient for testing a pasted path link or reload. `build/` is generated output; change `web/index.html`, Dart source, or assets, not compiled files.

## Validation by kind of change

| Change | Useful checks |
| --- | --- |
| Documentation only | Verify relative links, example commands, terminology, and generated-versus-source distinctions; no app rebuild is needed |
| UI or input | Format changed Dart, analyze, relevant widget tests, desktop/narrow-browser inspection |
| Calculations or chart geometry | Domain/consistency tests, chart tests, numerical audit when source interpretation changes |
| Research input or catalog | Import, format generated Dart, audit, library/consistency/share-codebook tests, source review |
| URL serialization or persistence | Share-state tests, size report, real-browser direct path/reload/history/clipboard checks, Wasm build |
| Browser integration or SDK/dependencies | Analyze, full tests, Wasm release build, supported-browser smoke check |
| Hosting/routing | Dry run, local direct path check, authenticated deployment receipt, public checks when authorized |

The usual application checks are:

```sh
flutter analyze
flutter test
flutter build web --wasm --release --no-web-resources-cdn
```

For targeted development:

```sh
flutter test test/share_state_test.dart
flutter test test/consistency_test.dart test/dyno_data_test.dart
dart scripts/report_share_sizes.dart
```

Run the relevant checks once for the final inputs. Repeat them after further changes or a failure, rather than repeatedly rebuilding unchanged inputs. Do not call a historical test count a current result.

### Test map

| Suite | Main coverage |
| --- | --- |
| [`consistency_test.dart`](../test/consistency_test.dart) | Torque averaging, five-percent gate, physical consistency between samples, interior HP peaks, normalization, and display formatting |
| [`dyno_data_test.dart`](../test/dyno_data_test.dart) | Weights, total load, source ranges, curves, conversions, and data assumptions |
| [`share_state_test.dart`](../test/share_state_test.dart) | Round trips, exact numeric values, invalid data, minimal packets, permanent IDs, ignored local state, order/colors, and restored UI |
| [`library_test.dart`](../test/library_test.dart) | Editorial membership, sourced catalog entries, model-generation separation, source-only safeguards, search, and mobile library |
| [`catalog_expansion_test.dart`](../test/catalog_expansion_test.dart) | Family coverage, paired baselines, historical model presets, weight-only selection, matching-stock mass, and mobile research panel |
| [`widget_test.dart`](../test/widget_test.dart) | Comparison controls, presets/custom input, rider/gear, normalization, same-bike comparisons, hover/touch, and layouts |

Widget tests load the bundled Manrope font to make layout checks meaningful. They use the browser stub, so they do not exercise a real Clipboard API, storage policy, network loader, or certificate. Existing responsive checks span narrow mobile and desktop sizes, including 320 and 1440 pixels. Preserve those cases when changing selectors, card layouts, chart margins, or tooltips.

Some tests deliberately assert known dataset totals or initial editorial membership. New researched records may require updating those assertions. Do not weaken a test merely because a source is incomplete or a reconciliation fails the user review gate.

## Common changes

### Add a bike, tested build, or weight preset

Follow the [catalog maintenance runbook](catalog-maintenance-runbook.md) and [data workflow](data-workflow.md). Edit reviewed research input rather than generated Dart. Record the exact tested model, hardware, chart, method, weight basis, and limitations. Replay any later power-chart sampling with `python3 scripts/verify_sampling.py`, regenerate, review the output, run the audit, and update tests intentionally.

Append new drawable configuration IDs and weight references to `lib/share_catalog.dart`. The codec tests check coverage. Do not reorder or remove existing entries. Prefer a source-only record over a fabricated curve when evidence is incomplete.

### Change a comparison control

Start in `ComparisonPage` and `Selection` in `main.dart`. Use `change()` / `save()` for valid committed values. Preserve the last valid numeric input when editing is incomplete. Keep per-card weight independent from the shared rider/gear load.

Decide explicitly whether a new setting belongs in the URL, local storage, transient widget state, or derived state. The user chose small comparison-only URLs. Adding library navigation, colors, visibility, or cursor state back to the wire would reverse that decision.

### Change chart behavior

Start in `dyno_chart.dart`, but put physical calculations in `dyno_data.dart` so the painter, tooltips, peaks, and CSV agree. Do not implement a second interpolation formula in the UI. Verify the full RPM domain, separate axes, same-RPM markers, labels near chart edges, and no extrapolation.

### Change sharing

Read [compact sharing](compact-sharing.md) and the stable codebooks first. New links have no version/checksum. Encoding incompatible semantics into the same unversioned bytes can silently change what an old link means. Preserve the format or deliberately document a breaking change; the old JSON and earlier compact formats were retired at the user's request.

Keep numbers exact. Avoid adding weight when a preset can identify it, and do not store the comparison count: entries continue until end-of-payload. Run the size report and confirm the restored comparison in a fresh context with different local settings.

### Change browser code

Use `dart:js_interop` / `package:web` through `lib/platform/`, preserving the conditional test export. Avoid introducing `dart:html` into Wasm code. Update both web and stub interfaces when adding an operation. Exercise storage-disabled and clipboard-failure behavior where relevant.

### Change deployment

Read [deployment](deployment.md). Keep SPA fallback and the root base URL for path links. Upload the whole static build. A change to this documentation or to research source JSON alone does not require publishing the site, and deployment is separate from a source commit/push.

## Troubleshooting

| Symptom | First places to check |
| --- | --- |
| Importer fails on a missing file | Its required family/coverage inputs and referenced chart assets; restore inputs before regenerating |
| Generated library differs unexpectedly | Dataset order, family aliases/defaults, generator edits, and formatting |
| A new bike is absent | Generated data, `hasCurve`, valid default weight, category filters, codebook coverage, and whether the browser is serving a rebuilt release |
| Curve shows impossible HP/torque relationship | Torque units, RPM mapping, reconciliation, and whether an independent HP interpolation was introduced |
| Audit returns exit code 2 | Inspect per-point and interpolation flags; report any >5% difference before applying |
| A preset changes to Custom after sharing | Current mass differs from frozen reference, or historical ID no longer matches the family; inspect both codebook and current preset |
| Reload resets library/visibility | A valid comparison path takes precedence; those local navigation/display preferences are intentionally omitted from shared links |
| URL appears unchanged after library/cursor changes | Expected: those values are not shared |
| Wasm build fails after new browser integration | Unsupported Dart library/package or missing conditional export |
| Build mentions CupertinoIcons but icons look correct | The historical build emitted a nonfatal missing-family warning; inspect actual icon usage before adding an unnecessary package |
| Root works but direct share path fails | Preview server / Cloudflare SPA fallback and root asset base |

## Useful future improvements

These are opportunities, not features claimed to be implemented:

- Pin the Flutter and Wrangler toolchains and add CI for validation/builds.
- Broaden generation input completeness checks beyond the later sampling ledger's maintained replay and the existing catalog tests.
- Add a maintained chart-calibration/digitization workflow or import original run files when licensed and available.
- Split the large main library into focused state, controls, source-dialog, and export modules.
- Add real-browser regression checks for direct path loading, history, clipboard, Wasm loading, and responsive chart labels.
- Expand primary-source tune coverage while retaining source-only records where evidence is insufficient.
- Track evidence review dates and quantitative uncertainty where it can actually be established.

Review [project decisions](project-history.md) before adopting these changes so improvements preserve the intended product.
