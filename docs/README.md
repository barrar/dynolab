# DynoLab documentation

Start with the [project README](../README.md) to run the app and understand the comparison controls. These guides explain how to maintain and extend it.

| Guide | Use it for |
| --- | --- |
| [Secret scanning and publication](security.md) | Initial audit scope, repeatable scanning commands, ignored local files and credential boundaries |
| [Current state](current-state.md) | Completed catalog work, dated validation, environment context, research gaps and continuation pointers |
| [Catalog maintenance runbook](catalog-maintenance-runbook.md) | Repeat a full motorcycle/tune expansion: search, group models, preserve mass and run provenance, pair baselines, validate, and hand off |
| [Deployment](deployment.md) | Cloudflare setup, authentication, a repeatable WebAssembly release, DNS/HTTPS, verification, and rollback |
| [Architecture](architecture.md) | Code ownership, data models, state flow, chart rendering, browser integration, and exports |
| [Development](development.md) | Toolchain setup, local preview, tests, common changes, and troubleshooting |
| [Data workflow](data-workflow.md) | Finding primary sources, digitizing charts, recording uncertainty, importing records, and reviewing numerical changes |
| [Project decisions and history](project-history.md) | What has been built, why key choices were made, and what remains worth improving |
| [Compact sharing format](compact-sharing.md) | Exactly what goes into a link, binary encoding, stable IDs, and size measurements |

## Research evidence

These are source-review records, with their original review dates. They do not establish that a product page, specification, or model lineup is still current. Recheck the publisher when updating a record.

| Record | Coverage |
| --- | --- |
| [Original research](research.md) | Honda CRF300L / 550 Performance, KTM 390 Euro 5b / COOBER, original weights, and provenance limitations |
| [Adventure research](adventure-expansion.md) | The initial ten-pick U.S. editorial adventure selection and its test-year references |
| [Dual-sport research](dual-sport-expansion.md) | The initial dual-sport selection and requested Honda F / CBR models |
| [KTM 390 research](ktm390-expansion.md) | Additional stock test, intake/exhaust/tuning evidence, and source-only records |
| [November 3 family and tune review](tuning-research-2026-11-03.md) | All 28 families, 30 added upgrade records, five new families, accepted/rejected evidence and model caveats |
| [Additional catalog records](catalog-expansion.json) | Additional stock tests, exact source links, weights, and limitations |
| [Additional tuning records](tuning-expansion.json) | Reviewed builds, hardware, published baselines, gain descriptions, and source-only evidence |
| [Family research coverage](tune-coverage.json) | A research outcome for each family, including where further usable tune curves were not found |
| [Chart sampling ledger](dyno-sampling.json) | Pixel samples, calibration axes, trace identity, canvas size, and power-unit conversion factors for later digitization |
| [Consistency audit](dyno-consistency-audit.md) | Per-curve torque/horsepower adjustments and the five-percent review gate |
| [Per-point audit CSV](dyno-consistency-points.csv) | Human-readable original and calculated values with percentage changes |
| [Full-precision audit JSON](dyno-consistency-audit.json) | Machine-readable originals, calculations, and review flags |

Research JSON and `assets/charts/` are the evidence inputs. `lib/researched_data.dart` is generated application data. The [data workflow](data-workflow.md) lists the generator inputs and explains which files to edit.

## Keeping these guides accurate

- Update source notes and the audit with numerical data changes.
- Update [compact sharing](compact-sharing.md) with serialization changes, and retain stable catalog codes.
- Update the release instructions when changing the build command, hosting provider, hostname, or routing.
- Describe historical checks as historical. A prior successful build or deployment is not proof that changed inputs pass today.
- Keep secrets, login links, and temporary upload credentials out of documentation and public build output.

The former [deployment handoff](cloudflare-deployment-handoff.md) is superseded by the deployment guide; its old paused-deployment instructions no longer apply.
