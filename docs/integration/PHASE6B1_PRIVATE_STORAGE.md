# Phase 6B.1 private storage and malware scanning

## Local private storage

`LocalPrivateStorage` implements upload initiation/completion, opaque object references, owner checks, purpose/type/size/digest/filename validation, quarantine, scan-state application, owner-only short-lived access, revocation and audit events. It stores bytes nowhere and produces only a `local-private://` simulation URL.

Allowed purposes are artist verification, legal agreement, certificate, order document, shipping document and operational attachment. The maximum synthetic size is 25 MiB. MIME declarations are checked against file signatures for PDF, PNG and JPEG; plain text rejects NUL content. A mismatched owner, public-style filename, unsupported type, invalid digest or invalid TTL fails closed.

## Malware scanning

`MalwareScanner` supports pending, clean, infected, failed and quarantined states. The local scanner simulates clean, infected, timeout and unavailable outcomes and deduplicates scan requests. The EICAR marker is recognized only as synthetic test content. Access is allowed only after `clean` when scanning is required; failed, missing, infected or quarantined states deny access.

## Media boundary

The 26 rights-approved public artwork images remain untouched in `public/media/heritage`. The 23 unresolved source assets remain quarantined outside the public application. Private legal/identity/commerce media is never placed in the public artwork path.

Real activation requires MED-01/02 approval, separate development/production private buckets, scoped storage secrets, signed-link duration, retention/legal holds, malware provider, quarantine worker, encryption/access audit and incident response. No bucket, upload, signed internet URL or scanner connection was created.

