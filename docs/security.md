# Secret scanning and publication

The initial GitHub publication was prepared on November 5, 2026 with Gitleaks 8.30.1. A full workspace scan, including generated build files, tool caches and local Cloudflare state, scanned approximately 97.25 MB and detected no secrets. Scan reports are kept outside the project.

Before pushing, scan the files selected for publication and all Git history with redaction enabled. This checkout had no Git history before its initial publication; there are no earlier local commits to audit.

```sh
gitleaks dir --redact --no-banner --ignore-gitleaks-allow --max-archive-depth 2 .
gitleaks git --redact --no-banner --ignore-gitleaks-allow --log-opts=--all .
```

The source repository excludes `build/`, `.dart_tool/`, `.wrangler/`, editor state, local environment files, secret directories, private-key containers and Python caches. An obsolete Cloudflare sign-in screenshot is retained locally and excluded from publication. Only a deliberately non-secret `.env.example` may be checked in if one is added in the future. Authentication stays in the local credential store or connected service; no deployment credentials are required to run the app.

The Cloudflare account/zone IDs, Worker/version IDs, public hostname, publisher links and encoded motorcycle-comparison paths in the source are public identifiers, not credentials. Publisher chart attribution and the Manrope font license remain with their assets. Do not add upload-session tokens, OAuth URLs or credential values to research notes, command examples or release receipts.
