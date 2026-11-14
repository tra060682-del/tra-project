# Phase 6B.1 provider readiness

## Status

| Category | Implemented adapter | Local test | Future configuration | Security requirements | Activation blocker |
|---|---|---|---|---|---|
| Payment | `PaymentGateway` + local intent/event adapter | PASS | provider account/key, secret, webhook signing secret, callback allowlist | server-only secrets, signed callbacks, replay retention, exact order/amount/currency, transactional RPC | PAY-01/02/03, DB-02/04 |
| Refund | payment gateway refund contract | PASS | refund-capable provider scope | bounded refundable amount, idempotency, verified completion, compensating ledger | REF-01 plus payment gate |
| Email | `EmailGateway` + local capture | PASS | provider token, verified sender/domain, callback secret, DNS | consent/suppression, token redaction, idempotency, retry/dead-letter | MSG-01/02 |
| Notifications | local channel dispatcher | PASS | approved database/outbox and optional email worker | own-user RLS, mandatory-category policy, dedupe, no false delivery | DB-04, MSG-02 |
| Private storage | `PrivateStorageGateway` + in-memory private adapter | PASS | separate private bucket/account/scoped keys/signing config | owner/purpose checks, opaque key, short TTL, encryption, audit, revocation | MED-01, DB-04 |
| Malware | `MalwareScanner` + local state adapter | PASS | scanner identity/endpoint/token or isolated worker | quarantine until clean, authenticated result, timeout/unavailable denial | MED-02 |
| Background jobs | deterministic local runner | PASS | Cloudflare Queue/DLQ bindings and worker config | idempotency, leases, bounded retries, dead-letter, cancellation/runbook | operations approval |
| Scheduled jobs | deterministic scheduler | PASS | Cron Trigger bindings | unique schedule claims, overlap/missed-run handling, job audit | operations approval |
| Monitoring | local structured logger/health | PASS | approved sink and alert destination | redaction, retention, least privilege, SLO/on-call | OPS-01/PROD-01 |
| Alerting | local dedupe/suppression manager | PASS | external routing credentials/webhook if selected | severity/threshold, suppression, escalation ownership | OPS-01 |
| Certificate | local token/hash/filter/rate-limit verifier | PASS | approved RPC, edge/app rate limit and flag | non-enumerable token, minimal response, revocation/audit | CERT-01, DB-04 |
| Auction | isolated load adapter; existing PostgreSQL controls retained | PASS | none until separate launch program | DB serialization, eligibility, Finance denial, kill switch, per-auction approval | AUC-01 and finance/legal readiness |
| Reconciliation | pure comparison contract | PASS | provider evidence reader, approved scheduled job and exception queue | immutable evidence, per-currency comparison, segregation of duties | PAY-02, REF-01, SET-01, COM-01, OPS-01 |

## Administrative diagnostics

`/admin/integrations` is restricted by `integrations.manage` and reports configuration, approval and operation separately. It renders no environment value and exposes no mutation. Expected Phase 6B.1 states are not configured/disabled/local-only; every operational value is false.

Required variable names are intentionally server-only. Local simulation needs `TRA_INTEGRATION_MODE=local` and the exact local approval marker in addition to the related test configuration. Real/provider modes are unsupported. `NEXT_PUBLIC_*` is prohibited for integration secrets.

## Phase 6B.2 connection candidates

After explicit approval, the next candidates are one payment sandbox, one transactional email sandbox and one separate private development bucket/scanner. They can be connected independently. Queue/monitoring may follow once a provider workflow needs asynchronous execution. Courier integration is not required for the artist-led pilot. Live auctions should remain last.

Connecting an account, adding a secret, creating a provider object, sending a message, uploading a real file, applying a migration or toggling a feature are separate approvals. The recommendations in `PHASE6A5_APPROVAL_REGISTER.md` are not approvals.

