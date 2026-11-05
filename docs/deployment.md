# Deploying DynoLab

Use the **authenticated Cloudflare connector**, the method used by the last successful deployment on November 5, 2026.

## Target

| Setting | Value |
| --- | --- |
| Website | <https://moto.bendtrailmaps.com/> |
| Worker | `moto-dynolab` |
| Account ID | `99288541d2d5c75cb721eaa932ea7df4` |
| Build directory | `build/web` |
| Compatibility date | `2026-11-02` |
| Navigation fallback | `single-page-application` |

Keep the existing Worker and domain binding.

## 1. Build

From the project root:

```sh
flutter build web --wasm --release --no-web-resources-cdn
```

The last deployment used `/private/tmp/assetcapture-flutter-sdk/bin/flutter`. See [toolchain setup](development.md#toolchain) if `flutter` is unavailable.

## 2. Prepare the upload

Generate a manifest for every file under `build/web`, excluding paths with dot-prefixed components such as `.DS_Store` and `.last_build_id`. Include the complete application, renderer resources, fonts and chart assets.

Each manifest key is a root-relative URL path, such as `/main.dart.wasm`. Its value contains:

- `hash`: the first 32 hexadecimal characters of SHA-256 over the file's raw bytes.
- `size`: the file size in bytes.

## 3. Upload changed assets

Use the Cloudflare connector's API search and execute tools with the account ID above.

1. Send `{ "manifest": <generated manifest> }` to `POST /accounts/{account_id}/workers/scripts/moto-dynolab/assets-upload-session`.
2. Keep the returned `result.jwt` and `result.buckets` in memory. Each bucket lists the hashes of files that need uploading.
3. Upload each bucket to `POST https://api.cloudflare.com/client/v4/accounts/{account_id}/workers/assets/upload?base64=true`, using `Authorization: Bearer <upload-session JWT>`. Send multipart form data: each part's name is the file hash, its content is the file's base64-encoded bytes, and its content type is the file's MIME type. Use `application/wasm` for `.wasm` and `text/javascript` for `.js` and `.mjs`.
4. Retain the completion JWT returned after all requested files are uploaded. If `buckets` is empty, the session JWT is already the completion JWT.

The last release used `/private/tmp/moto-cloudflare-uploader.mjs`, a temporary Node.js helper for step 3. It accepts one JSON line containing `accountId`, `jwt`, `buckets` and `manifest` through hidden stdin; send terminal input in chunks of at most 1,024 characters. Its `SEALED_RESULT` encrypts the completion JWT with AES-256-GCM, using SHA-256 of the upload-session JWT as the key and base64 `iv`, `ciphertext` and `tag` fields. Decrypt in memory before publishing. If the helper is missing, recreate the bucket uploader using the API steps above.

Create a fresh upload session for each release. Keep JWTs out of terminal output, project files and documentation.

## 4. Publish

Through the authenticated connector, send multipart form data to `PUT /accounts/{account_id}/workers/scripts/moto-dynolab`.

Include a `metadata` part with content type `application/json`:

```json
{
  "main_module": "no-op-worker.js",
  "compatibility_date": "2026-11-02",
  "assets": {
    "jwt": "<completion JWT>",
    "config": {
      "not_found_handling": "single-page-application"
    }
  }
}
```

Include `no-op-worker.js` with content type `application/javascript+module`:

```js
export default {
  fetch() {
    return new Response("Not found", {
      status: 404,
      headers: { "Content-Type": "text/html" }
    });
  }
};
```

The upload publishes the new version automatically. Record `success`, `modified_on` and `deployment_id` from its response. Finish after a successful publication receipt; public-site browser checks are performed only when requested.
