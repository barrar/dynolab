# Deploying DynoLab

DynoLab is a static Flutter website. Production uses **Cloudflare Workers Static Assets**, served through the Worker Custom Domain **moto.bendtrailmaps.com**. There is no Pages project, database, application API, or server-side share-link service.

This guide documents the existing project and recorded deployment setup as of November 3, 2026. It does not perform a deployment or a live DNS/certificate check. Inspect the account before changing infrastructure.

## Deployment identity

| Setting | Value |
| --- | --- |
| Production URL | <https://moto.bendtrailmaps.com/> |
| Worker | `moto-dynolab` |
| Cloudflare zone | `bendtrailmaps.com` |
| Account ID | `99288541d2d5c75cb721eaa932ea7df4` |
| Zone ID recorded during setup | `9ce5887e56e664fc9bfac001ceb5d414` |
| Configuration | [`wrangler.jsonc`](../wrangler.jsonc) |
| Public upload directory | `build/web` |
| Route | `moto.bendtrailmaps.com`, `custom_domain: true` |
| Missing navigation path | Root `index.html`, using `single-page-application` handling |
| Compatibility date | `2026-11-02` |
| Alternate public hosts | `workers.dev` and preview URLs disabled |

Account and zone IDs are identifiers, not authentication secrets. The checked-in configuration pins the deployment account to reduce accidental publication into another account.

The Worker Custom Domain provisions the hostname's Cloudflare-managed DNS record and certificate. During initial setup, an existing zone ruleset received a **hostname-specific HTTP-to-HTTPS redirect** for `moto.bendtrailmaps.com`. It preserves both the path and query string. The apex and other subdomains were left unchanged. That redirect rule is managed separately from this project's Wrangler file.

Do not manually replace the managed DNS record with the IP address returned by a resolver. Do not assume a DNS answer proves the custom domain or certificate is active.

## Prerequisites

- A working Flutter SDK with the Dart version required by [`pubspec.yaml`](../pubspec.yaml). The development SDK used here is Flutter 3.44.0 / Dart 3.12.0; see [toolchain notes](development.md#toolchain).
- Node.js suitable for Wrangler 4, plus npm/npx.
- Cloudflare account access to this Worker and the `bendtrailmaps.com` zone.
- A clean, understood set of release inputs: source code, generated data, chart assets, lockfile, and configuration.

The repo has no deployment pipeline or pinned local Wrangler dependency. The commands below use `npx --yes wrangler@4`. For a release process shared by multiple maintainers, choose a tested exact Wrangler version and record it with the release. Local CLI help was checked with Wrangler 4.157.0 while preparing this guide; earlier deployments used the 4.x CLI and the authenticated Cloudflare connector.

## Authenticate

From the project root:

```sh
npx --yes wrangler@4 whoami
```

If that reports expired or missing authorization, renew the CLI login:

```sh
npx --yes wrangler@4 login
npx --yes wrangler@4 whoami
```

Complete sign-in in the browser. Do not copy passwords, tokens, authorization codes, or OAuth URLs into project files. Authentication for an editor's Cloudflare connector is separate from Wrangler authentication; a working connector does not renew a CLI login.

For automation, use an appropriately scoped Cloudflare API token in the job's secret store, exposed as `CLOUDFLARE_API_TOKEN`. Grant the Worker/account and zone permissions needed by the operation; a content update and initial hostname setup may need different permissions. Never put a token in `wrangler.jsonc`, Dart code, a URL, or a shell command that will be saved to documentation.

## Build a release

Run commands from the project root and stop if any command fails:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --wasm --release --no-web-resources-cdn
```

If the normal `flutter` executable is unavailable on the original Mac, the temporary SDK may still exist:

```sh
MOTO_FLUTTER_BIN=/private/tmp/assetcapture-flutter-sdk/bin/flutter
"$MOTO_FLUTTER_BIN" --version
"$MOTO_FLUTTER_BIN" build web --wasm --release --no-web-resources-cdn
```

That `/private/tmp` path is a local recovery workaround, not a portable dependency or durable installation. Use a complete SDK on a new machine. Do not substitute a JavaScript-only build when the intended release is WebAssembly.

The build includes `main.dart.wasm`, `main.dart.mjs`, Flutter's JavaScript compatibility fallback, bundled renderer resources, fonts, and chart images. Upload the entire `build/web` directory together. Copying only the `.wasm` file produces an incomplete site.

The upload boundary matters: **only `build/web` is public**. Source research documents, credentials, editor state, and temporary upload tools do not belong there. Flutter assets are public too; a credential in a bundled JSON or image metadata is still published.

## Preview before publishing

```sh
./scripts/serve.sh
```

The default address is <http://127.0.0.1:52741/>. For a second preview use `PORT=52742 ./scripts/serve.sh`. Stop the server with Ctrl-C when finished.

The preview implements navigation fallback. Open a comparison link by its full path, reload, and confirm the bikes, weights, normalization, and chart mode. A plain file server can display the root while returning a 404 for direct share links; use this project's server for that check.

Keep `<base href="/">` in the compiled `index.html` for this root-hosted deployment. A share token is a state path, not the directory containing the app's scripts, fonts, or images. `DynoLabApp` intentionally starts Flutter at `/` and restores state separately.

## Inspect the target, then publish

Before the first deployment from a new account/session, inspect the Worker, custom domain, and any `moto` records in the Cloudflare dashboard or authenticated connector. Confirm they belong to DynoLab. Preserve unrelated DNS and redirect rules.

Validate the upload configuration without publishing:

```sh
npx --yes wrangler@4 deploy --dry-run
```

Publish the prepared release:

```sh
npx --yes wrangler@4 deploy --message "Describe this release"
```

Wrangler reads `wrangler.jsonc`, uploads `build/web`, and applies the configured custom domain. For an existing site, keep the Worker name, account, and route unchanged unless deliberately migrating hosting. Do not create a second Pages project as a deployment workaround.

Record the deployment output, CLI/SDK versions, and which source/data changes were released. If version control is available, record the source revision too. This workspace originally had no Git repository; a deployment should not be described as a commit or push.

## Connector-based deployment alternative

The existing site was also successfully published through the authenticated Cloudflare connector when the CLI login was expired. The underlying flow is:

1. Discover the upload-session and Worker-upload endpoints through the connector's current API schema.
2. Generate a path/hash/size manifest from the public build files.
3. Create an assets upload session for `moto-dynolab`.
4. Upload the requested missing asset buckets using the session's short-lived upload authorization.
5. Finalize a Worker upload with the completed asset token and `not_found_handling: single-page-application`.
6. Check the returned deployment receipt for success.

The earlier session used a temporary local uploader and a small no-op Worker module. Those temporary files and session tokens are **not a maintained release tool**. Use Wrangler for repeatable routine releases, or implement and review a proper deployment script before standardizing the API workflow. Never reuse an expired upload token, print tokens in logs, or store connector credentials in the repo.

For a small update to this already established target, use the authenticated connector immediately if the CLI login is known to be expired. Exclude local dotfiles such as `.DS_Store` and `.last_build_id` from the upload manifest. Upload only missing asset buckets, then finalize the existing Worker with the completed asset token and SPA configuration. Keep the established domain binding. A successful Worker upload receipt confirms publication; record its version identifier without treating it as a public-browser test.

When the user explicitly requests a deployment without checks, make the requested edit, build the WebAssembly release, publish it, and record the receipt. Skip analysis, tests, dry runs and browser checks for that release rather than repeating the full validation workflow above. The release build remains necessary to produce the files being deployed.

## DNS and HTTPS

Latest routine release: November 5, 2026, `2026-11-05T21:56:13.324568Z`, version `a9f63aa4919247f68af55fecce559c28`. Motorcycle selectors and library collections now sort by brand, then model. Published through the authenticated connector with three changed assets. Analysis, tests, dry runs and browser checks were skipped at the user's explicit request; the WebAssembly build and Cloudflare upload completed successfully.

For an existing installation, verify the custom domain is still bound to `moto-dynolab` in the owning account. Cloudflare manages its DNS and certificate. A conflicting pre-existing hostname must be investigated before replacement.

If provisioning another hostname, configure a Worker Custom Domain and let Cloudflare create its managed record. Check the zone is active, the certificate reaches an active state, and no conflicting record or application is serving the hostname. The separate redirect should match **only the intended hostname**, use HTTPS, and preserve `http.request.uri.path` and the query string. Do not toggle a zone-wide setting merely to fix one subdomain.

DNS can retain negative answers from before a hostname existed. Distinguish a local resolver cache from authoritative DNS and certificate status. Wait for the relevant cache expiry or inspect another resolver; do not change the user's system DNS as a routine deployment step. Do not bypass certificate validation to make a check pass.

## Verify a release when requested

The user previously asked to stop loading the public site during deployment work. This documentation task does not revoke that preference. The following is a runbook for a future authorized public check; no public-site request is needed to edit these guides.

| Check | Expected result |
| --- | --- |
| Cloudflare deployment receipt | Success for `moto-dynolab` in the configured account |
| HTTPS root in a supported browser | App renders, certificate valid |
| Direct comparison path and reload | Same comparison settings restored |
| WebAssembly-capable browser network log | App `.wasm` and required renderer resources loaded successfully |
| Unsupported-Wasm browser | Flutter's generated JavaScript fallback loads |
| Shared link in a fresh browser context | URL state overrides different saved preferences |
| Invalid state path | Saved/default comparison remains usable, with no error toast |
| Changed cursor, scroll, or library navigation | Comparison token unchanged |
| Copy link | Current comparison settings copied; no pending update omitted |
| HTTP comparison URL | Redirects to HTTPS while preserving the state path |

A successful upload receipt is evidence of publication, not a browser compatibility test. A successful root request alone does not prove path restoration or WebAssembly execution.

## Rollback

Inspect recent deployments and identify the **Worker version ID**, not just a deployment ID:

```sh
npx --yes wrangler@4 deployments list --name moto-dynolab
```

For an authorized rollback, select a known good version from Cloudflare's deployment history and use:

```sh
npx --yes wrangler@4 rollback VERSION_ID --name moto-dynolab --message "Reason for rollback"
```

The rollback command asks for confirmation. Check asset/version availability and the resulting deployment receipt. If the desired assets are unavailable for rollback, rebuild the known good source and publish it normally. Reverting source files locally does not update the live site. Changes to separately managed DNS or redirect rules need separate recovery.

## Common failures

| Symptom | What to inspect |
| --- | --- |
| Expired Wrangler login | Renew CLI auth; connector auth is independent |
| Wrong account or route conflict | Compare `account_id`, Worker, zone, and custom-domain ownership |
| Root works, share link returns 404 | `single-page-application` handling and root `index.html` |
| Scripts requested under the token path | Root base URL and any changed bootstrap paths |
| Blank page or renderer failure | Browser console, Wasm support, resource MIME types, complete build upload |
| Build changed but site looks old | Deployment receipt and asset responses; reload after checking the new release exists |
| HTTPS works but HTTP stays HTTP | Hostname-specific redirect, which is outside `wrangler.jsonc` |
| New data absent from the site | Regenerate application data, rebuild, and deploy; editing JSON alone changes no published bundle |
