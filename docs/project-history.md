# Project decisions and implementation history

This is a maintainer's account of the work and product decisions so far, updated November 5, 2026. The code and dated research records are the authority for current behavior and source evidence. It is not a Git changelog or a claim that every source has been rechecked today. See [current state](current-state.md) for the completion handoff and dated validation.

## Product scope

The user requested a Flutter application for **desktop and mobile browsers**, comparing motorcycle horsepower and torque across RPM. Native mobile applications were explicitly out of scope. The app began with the Honda CRF300L and what the user called the KTM 390 Rally; the user clarified that this meant the **2025+ 390 Adventure R**.

The result is DynoLab: a static, client-side comparison workspace with up to four configurations, including different builds of the same bike. The data is bundled so comparison does not depend on a publisher API or runtime scraper.

## Work completed by area

| Area | Implementation and rationale |
| --- | --- |
| Initial stock/upgrade comparison | Honda stock and 550 Stage 1.0; KTM Euro 5b stock and COOBER LM ECU + DeCat. Exact hardware and provenance are visible. |
| Interactive chart | One persistent RPM marker and per-line labels/readouts; hover, touch/drag, and keyboard support. |
| Model/build selection | Independent selections, consistent dropdown appearance, same-bike comparisons, and model weights separate from dyno builds. |
| Weight-normalized output | One toggle scales HP and torque together. Per-pound presentation was changed to per **100** pounds at the user's request. |
| Shared load | Optional rider and gear added once to every comparison; disabling it retains the entered values. New load inputs use whole pounds. |
| Broader library | Editorial ten-pick U.S. Adventure and Dual sport collections, plus requested models and additional KTM tune research. These are not sales rankings. |
| Numerical consistency | Recorded torque averaged with torque implied by HP/RPM; all plotted horsepower derived from resulting torque. Original input samples are retained. |
| Precision | Calculations and custom bike weights retain precision; normal measurement displays and CSV use three significant figures. Whole-pound load input is a later UI exception. |
| Delivery | WebAssembly release with generated JavaScript compatibility fallback and bundled rendering resources/fonts. |
| Sharing | Important comparison settings automatically stored in a short path and exposed by Copy link; no backend share service. |
| Hosting | Cloudflare Workers Static Assets, custom domain, managed DNS/certificate, hostname-specific HTTP-to-HTTPS redirect. |

The requested additions included KTM 890, 500, and 350; Honda CRF250F, CRF300F, and CBR650R. The user explicitly confirmed the F-model names. Their categories remain honest: an off-road trail bike or road sport bike is not labeled a street-legal dual sport merely to fill a list.

## Data decisions worth preserving

### Evidence quality takes precedence over filling a graph

Only readable RPM traces become curves. Peak-only claims, unavailable primary graphs, unclear measurement basis, or ambiguous RPM mappings remain source-only evidence. Adding a tune name does not mean there is enough evidence to calculate a curve or a percentage gain.

The original KTM chart identifies a 390 Euro 5b engine platform, not an Adventure R-specific tested body model. Its power trace/header conflict led to sampling torque and deriving horsepower. Older 373 cc KTM Adventure/Duke runs remain identified as older-generation references. Weight scenarios and product fitment do not remove those caveats.

### Horsepower and torque must agree physically

An earlier implementation interpolated the source quantities separately. The user requested reconciliation of source torque against torque implied by recorded HP/RPM, then horsepower calculated from torque throughout the graph. The current function is linear torque and quadratic horsepower between samples. Peak finding and the painter were updated accordingly.

The user's review threshold is **greater than five percent**. The runtime gate and audit preserve that requirement. The November 2 baseline audit covered 405 points / 25 curves with no flagged exceedances. See [data workflow](data-workflow.md) for formulas, percentages, and the procedure for new inputs.

### Mass and power evidence stay independent

A Honda Rally or KTM Enduro weight is a mass preset. It is not a second dyno test. Published wet/as-tested weights include their stated equipment and fuel basis. The app assumes no upgrade weight saving. Custom weights allow an actual measured build to be compared without altering the underlying engine curve.

### Shared families and broader tune coverage

The November 3 expansion grouped related model variants under a family, including KTM 890, while exposing model-specific weights. Adventure and Duke calibrations retain separate tested runs. The older 373 cc KTM 390 family remains separate from the 399 cc Euro 5b engine. Permanent configuration IDs and frozen weight references were preserved for existing links.

The catalog grew to 28 families / 76 source records / 56 curves. Five added families include the source-only CB500X. Thirty added aftermarket records include 15 plotted tuned runs; all families have a recorded research outcome, including missing or rejected evidence. Linked same-source baselines support the matching-stock action with equal comparison mass. The [dated research report](tuning-research-2026-11-03.md) preserves the sources and caveats; the [maintenance runbook](catalog-maintenance-runbook.md) explains how to repeat the work.

The expanded audit covers 807 source points with zero source-point or intermediate flags over 5%. A maintained sampling replay checks the 402 later power-derived points against saved pixel calibration; it complements visual source review and the physical consistency audit. The earlier 405-point result above remains historical context.

## Sharing evolved deliberately

The first links used Base64-encoded JSON with long property and catalog names. They were replaced by compact binary IDs/flags and implicit preset weights. The user then prioritized fewer characters and removed the wire version, checksum, and query-parameter wrapper, choosing a path such as `/AGDCAQ`.

Further simplification removed colors, units, library/source navigation, and an explicit comparison count. Colors now follow comparison position, torque is always lb-ft, entries are read to the end, and links restore only the comparison. Visibility and cursor/scroll were excluded by explicit user direction. Invalid state is silently ignored. Previous link formats were retired; supporting them was not a requirement.

Consequences for future development:

- The format is unversioned and has no corruption checksum. An edited/truncated token that still describes complete valid entries can be accepted.
- Stable configuration/preset codebooks must be append-only; preset reference masses must remain frozen.
- Shared state is encoded, not encrypted. Anyone with a link can read its comparison settings and included weights.
- The local JSON snapshot is wider than the shared state; do not serialize it wholesale into the path.
- There is no persistent URL lookup table, shortening service, or expiry timer.

The exact contract and current measurements are in [compact sharing](compact-sharing.md).

## Deployment history and boundaries

The initial deployment was temporarily blocked by expired CLI authorization and unavailable connector access. A historical handoff described that pause. Cloudflare access subsequently became available and deployments completed; that handoff is superseded by [deployment](deployment.md).

The chosen service is Workers Static Assets, not Pages. Initial infrastructure setup bound `moto.bendtrailmaps.com` to `moto-dynolab`, provisioned managed DNS/HTTPS, disabled alternate Worker hosts, and added a redirect scoped to this hostname. Later releases uploaded changed static assets. No database, runtime API, or account system was introduced.

There were successful local tests, Wasm builds, shared-state restoration checks, and Cloudflare deployment receipts. Public checks were curtailed when the user said not to keep trying to load the deployed website. Do not describe an upload receipt as a complete public-browser verification, or resume those checks just because an old checklist lists them.

Editing documentation does not authorize a new release, a Git repository creation, or a push. Follow the user's current request for publication.

## Known limits and future direction

The graph is exploratory, not a controlled performance test or acceleration simulation. Publisher dynos, correction standards, tires, markets, model years, and accessory loads differ. Manual digitization has uncertainty; a label with three significant figures is display consistency, not that level of measurement accuracy.

The catalog and source-only coverage can grow, but curated evidence remains essential. Original raw run files, a reproducible digitization tool, CI/toolchain pinning, and broader real-browser testing would improve maintainability. These are development opportunities, not completed features. See [development](development.md#useful-future-improvements).
