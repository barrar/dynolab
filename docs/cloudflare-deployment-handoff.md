# Deployment handoff — superseded

The paused-deployment handoff prepared November 2, 2026 is obsolete. Cloudflare access subsequently became available, and DynoLab was deployed to **https://moto.bendtrailmaps.com/** using the `moto-dynolab` Worker, managed DNS/HTTPS, and a hostname-specific HTTP-to-HTTPS redirect.

Use the maintained [deployment runbook](deployment.md) for authentication, release builds, account/configuration details, publication, verification, and rollback. The [documentation index](README.md) links the architecture, research workflow, development guide, numerical audits, and project decisions.

Earlier `state` JSON and `s` query links are no longer the current format. Shared comparisons use an unversioned path payload without a checksum; see [compact sharing](compact-sharing.md). Do not restore old serialization behavior from this handoff.

The user previously asked to stop loading the public site during deployment checks. Documentation updates do not resume those checks or authorize another release. Inspect the current account and follow the user's current instructions before making external changes.
