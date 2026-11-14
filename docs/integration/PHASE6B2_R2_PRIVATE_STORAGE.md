# Phase 6B.2 R2 private storage

## Implemented contract

The R2 adapter accepts an injected Worker `R2Bucket`-compatible binding. It validates owner, purpose, filename, MIME, size and magic bytes; creates opaque private keys; uploads as quarantined; requires a clean scan; emits audit events; issues an application endpoint token valid for at most five minutes; and deletes/revokes objects.

The signed token contains an opaque object identifier, actor identifier and expiry protected by HMAC. It is not a permanent R2 URL. A future download route must repeat authentication, active-account, RBAC, ownership/representation, scan and revocation checks before reading the binding.

Official references: [R2 Workers binding API](https://developers.cloudflare.com/r2/api/workers/workers-api-reference/) and [R2 data-access security](https://developers.cloudflare.com/r2/data-access/).

## Boundaries

- Public Cloudinary artwork media remains separate.
- The 26 approved images are unchanged.
- The 23 unresolved images remain outside public deployment assets.
- No bucket, binding, object, signed URL or private route was created.
- Metadata persistence needs the unapproved Phase 6A migration and RLS.

Approve MED-01, development bucket/region, lifecycle and retention, five-minute maximum access, scoped Worker binding, scan provider and incident ownership before connection.
