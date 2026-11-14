# Phase 6B.1 monitoring and alerting

## Structured local logging

`LocalStructuredLogger` records timestamp, level, service, operation, correlation ID, request ID, event category, outcome, duration, error class and bounded detail. Recursive redaction replaces values whose keys indicate passwords, tokens, secrets, authorization/cookies, cards/banks, payloads/documents, email, phone or address. Bearer credentials, common secret prefixes and private-key headers are also redacted.

Logs must never become an audit/ledger substitute. Financial and security state remains in immutable database records after the approved migration. Local records are for tests and diagnostics only and are not exported.

## Health and diagnostics

Health separates `mode`, `configured`, `approved` and `operational`. Configuration presence cannot prove approval or connectivity. `/admin/integrations` requires `integrations.manage`, reads diagnostics server-side, exposes no values and provides disabled controls only.

The Phase 6B.1 expected status is: payment/email/private storage/malware not configured; background/scheduled jobs disabled; monitoring local only; certificate verification and live auctions disabled. Even an explicitly approved local simulation remains `operational: false` in the administrative production-readiness view.

## Alerts

`LocalAlertManager` covers payment verification, reconciliation, webhook, notification, storage, malware, auction integrity, job failure and certificate anomaly. Severities are informational, warning and critical. Stable alert keys deduplicate/suppress repeated events inside a configured window while increasing the count.

Future external monitoring requires destination and retention approval, redaction review, service-level objectives, on-call routing, escalation/suppression rules and least-privilege ingest credentials. No external log, trace, error or alert service is configured.

