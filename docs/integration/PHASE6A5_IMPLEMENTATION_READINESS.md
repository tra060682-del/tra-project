# Phase 6A.5 implementation readiness

## Executive result

The codebase is ready for controlled Phase 6B development, but not for migration application, real provider configuration, transaction activation or production release. Application contracts, disabled feature gates, additive SQL proposals, rollback scripts and isolated security tests are present. The critical path is approval and application of Phase 3 database authorization before the Phase 6A commerce schema.

Development-only adapters, synthetic fixtures, local workers and security tests can proceed now without deciding every tax, settlement or auction policy, provided they remain disconnected from real accounts and all operational flags remain disabled.

## Evidence baseline

- Branch baseline: Phase 6A commit `a7af7b0`, based on Phase 5 `d205172`.
- Development Supabase read-only inventory: 39 public tables and seven applied repository migrations at the Phase 6A verification point.
- Staging: the established 400-record mapping remains unpromoted and outside application queries.
- Phase 3 and Phase 6A draft migrations are unapplied.
- Phase 3.5 and Phase 6A forward/RLS/transaction/rollback rehearsals passed in disposable PostgreSQL/Supabase environments.
- Phase 6A validation: 40 unit, 44 integration and 59 browser tests passed; Next.js and Cloudflare development builds passed.
- Production infrastructure, providers, credentials and feature flags were not changed.

## Supabase migration readiness

### Required order

| Order | Package | Status | Required action | Blocks |
|---:|---|---|---|---|
| 1 | Current 39-table baseline | Verified read-only | Repeat schema inventory and backup evidence immediately before an apply | All applies |
| 2 | `202611140100_phase1_role_enum.draft.sql` | Rehearsed | Human review; convert to immutable migration | Phase 3 |
| 3 | `202611150100_phase3_role_enum.draft.sql` | Rehearsed | Human review; convert to immutable migration | Phase 3 |
| 4 | `202611150101_phase3_auth_rbac.draft.sql` | Rehearsed | Human review, bootstrap/runbook approval, fresh rehearsal, development apply approval | Phase 6A schema |
| 5 | `202611140102_phase1_catalogue_content_operations.draft.sql` | Rehearsed historically | Split/review only if remaining content capabilities are in scope | Phase 7 content, not payments |
| 6 | `202611170101_phase6a_commerce.draft.sql` | Rehearsed | Rebase against post-Phase-3 schema; human review; fresh rehearsal; development apply approval | Phase 6B persistence |
| 7 | Phase 6A verification and security SQL | Passed in isolation | Run after development apply with synthetic records | Feature enablement |

Never apply `202611140101_phase1_permissions_and_identity.draft.sql`. Never apply the old `202611140103_phase1_commerce_finance_auction.draft.sql` with Phase 6A. Their overlapping definitions are superseded.

### Apply prerequisites

Before any development apply, require all of the following:

1. Fresh remote schema-only dump with no row data or credentials.
2. Drift comparison against the verified 39-table baseline and current migration history.
3. Immutable migration IDs and checksums.
4. Human SQL review of functions, `search_path`, grants, RLS, foreign keys, indexes and lock behavior.
5. Named maintenance window, executor, observer and rollback owner.
6. Backup/export and restore verification appropriate to the affected environment.
7. Disposable forward, concurrency, RLS and rollback rehearsal using the fresh schema.
8. Separate explicit approval to apply to development.
9. Feature flags left disabled after successful apply.
10. Post-apply anonymous, cross-user, suspension, role-revocation, finance and audit tests.

Production application is a separate Phase 7 change and cannot reuse development approval.

## External-service readiness

| Capability | Recommended development integration | Secrets/configuration required | Current readiness | Activation gate |
|---|---|---|---|---|
| Payment | Provider-neutral adapter; preferred candidate Razorpay sandbox subject to commercial eligibility | sandbox key/account ID, secret, webhook signing secret, callback allowlist | Contracts/schema ready; provider absent | PAY-01/02/03 + DB-04 |
| Refund | Same payment adapter, worker-driven | payment credentials plus refund permission scope | RPC design ready; policy/provider absent | REF-01 + payment gate |
| Settlement | Manual controlled pilot first; provider adapter later | no banking secret in app; approved payout processor credentials if automated | Ledger/settlement schema ready | SET-01 + segregation controls |
| Email | Outbox worker with one transactional sandbox; preferred candidate Postmark | API token, verified sender/domain, callback signature secret, DNS records | Model ready; worker/provider absent | MSG-01/02 |
| Private media | Separate development R2 private bucket | account ID, bucket, scoped access key/secret, signing config | Metadata/audit model ready | MED-01/02 |
| Malware scan | Managed scanner or isolated scanning worker | scanner endpoint/token or worker identity | Integration point only | MED-02 |
| Background jobs | Cloudflare Queues/Workers or equivalent approved job runner | queue bindings, worker secrets, dead-letter config | Not configured | service-specific approval |
| Monitoring | Cloudflare/Supabase telemetry plus approved alert destination | read-only tokens/webhooks and alert routing | Build/test evidence only | operations approval |
| Courier | No live integration in initial pilot; record artist-supplied carrier/tracking | none initially; later provider token/webhook | Manual data model ready | shipping policy; not a 6B prerequisite |
| Identity linking | Controlled Clerk evidence source only | least-privilege Clerk export/API access if retained | Rules recommended; not implemented | ID-01 |

All development and production accounts, buckets, queues, sender domains and credentials must be distinct. Secrets belong in server-only environment/Cloudflare secret storage and must never appear in `NEXT_PUBLIC_*`, documentation, fixtures or client bundles.

## Policy readiness by transaction domain

### Offers, reservations and order creation

The transactional state/version and one-active-reservation controls are ready. Product approval is still required for offer minimum/expiry, counteroffer actors, reservation length/extension, cancellation, stale price handling and the exact point at which an accepted offer creates an order. These rules can be represented as configuration and tested locally before activation; acceptance and checkout stay disabled.

### Payments and refunds

The provider-independent intent, attempt, event, refund and ledger structures are ready. Implementation must preserve exact minor units, immutable price snapshots, server-verified callbacks, idempotency, replay protection and daily reconciliation. Provider choice, tax/fee rules and refund eligibility block real sandbox transaction flows that create provider objects. Pure adapter/signature fixtures do not need those final commercial percentages.

### Settlements and commissions

Ledger and settlement calculations can be developed against synthetic sales. No payable obligation or transfer may be created until hold/release, cadence, adjustments, dispute handling, bank-data processing and two-person approval are approved. Commission logic can use a synthetic agreement snapshot, but production rules need the binding entitlement event and post-revocation treatment.

## Transactional email and notification architecture

Recommended flow:

1. A committed business transaction inserts an in-app notification and an outbox/delivery row with a stable dedupe key.
2. A server-only worker claims the row with locking/lease semantics.
3. It renders an approved versioned template without placing sensitive data in the subject.
4. It calls the provider using the delivery idempotency key.
5. It records the provider reference and delivery result; transient failures use bounded exponential backoff and a dead-letter state.
6. Signed provider callbacks update delivery state idempotently.
7. User preferences apply only to optional categories; essential security/legal/payment/order messages remain mandatory under the approved policy.

Supabase Auth email may continue to handle identity verification/reset using its separately configured templates. Application invitations and commerce notifications must use the audited outbox rather than synchronous browser/server-action sending.

Safe before provider approval: define the provider interface, local capture adapter, template schemas, redaction rules, retry state machine and synthetic callback fixtures. Not safe: sending to real addresses, changing DNS, storing tokens, or reporting delivery success.

## Private-media readiness

Recommended architecture separates public artwork media from private documents. Public publication remains limited to the 26 approved assets or later rights-approved Cloudinary/R2 objects. Private legal, identity, order, shipping and certificate documents use an opaque key in a private bucket.

The request path is: authenticate and authorize purpose/owner; issue a short-lived constrained upload; finalize metadata and digest; quarantine; scan; mark clean; then permit short-lived signed reads after a fresh authorization check. Revocation prevents new links; every upload/view/download/revocation is audited. Application pages never persist signed URLs.

Safe before storage approval: implement an in-memory/local fake, file-signature validation, ownership tests, audit contracts, signed-URL expiry tests and synthetic clean/rejected scan events. Not safe: accepting real identity/legal files, issuing internet-accessible URLs or using the public artwork bucket.

## Certificate verification readiness

The disclosure contract is technically ready: opaque 256-bit token, database hash, generic absence, explicit revocation and a minimal projection. Before enabling public verification, approve artist-issued evidence requirements, public wording/fields, token delivery, revocation and appeal, rate-limit thresholds, cache behavior and incident response. Add edge and application throttling and monitor abnormal token attempts.

Safe before approval: token generation/validation tests, QR rendering with synthetic tokens, contract tests proving excluded fields and local rate-limit tests. The public RPC, route action and feature flag remain disabled.

## Auction readiness

Existing PostgreSQL bid serialization, request idempotency, maximum confidentiality, terminal-state protection and Finance exclusion remain authoritative. Phase 6B may improve launch-readiness UI, synthetic load tests, kill-switch rehearsal and operational checklists without enabling bids.

Live auctions additionally require approved bidder eligibility/terms, reserve confidentiality, per-auction dual launch approval, staffed incident response, payment/refund/settlement readiness, reconciliation, legal terms and a production load/security rehearsal. Finance / Operations remains prohibited from bidding even on a multi-role account.

## Identity and privileged access readiness

### Clerk linking

Linking is not required to build Phase 6B adapters. If legacy-account continuity is required for Phase 7, implement a dual-proof workflow that preserves Supabase UUIDs and never copies Clerk roles, passwords or sessions. Start with a synthetic evidence service and manual-review queue; do not access Clerk exports or API until ID-01 is approved.

### Super Admin

Phase 3 application logic correctly refuses automatic bootstrap. After Phase 3 is approved and applied to development, execute the UUID-specific two-person development runbook, require verified email/MFA, establish two independent administrators and verify audit evidence. Do not reuse the development approval or identities for production.

## Development work that can proceed now

These tasks are safe without final commercial policy approval, provided they use synthetic data, local/disposable services and disabled feature flags:

| Work item | Permitted boundary | Later approval still required |
|---|---|---|
| Final migration packaging | Review/split SQL and rerun disposable rehearsals; do not apply remotely | DB-01/02/04 apply approval |
| Payment adapter interface | Local fake, signature fixtures, idempotency/replay tests, no provider object | PAY-01/02 and credentials |
| Monetary engines | Synthetic minor-unit totals, ledger, refunds, settlement/commission scenarios | PAY-03, REF-01, SET-01, COM-01 |
| Email outbox | Local capture transport, template/version/redaction tests, retry/dead-letter simulation | MSG-01/02 and DNS/provider |
| Notification UI | Synthetic in-app records and preference contract tests | DB-04 and category approval |
| Private-media adapter | Local fake, MIME/signature/size checks, authorization and expiry tests | MED-01/02 and bucket/scanner |
| Certificate verifier | Synthetic token/hash/QR/disclosure/rate-limit tests with route disabled | CERT-01 and DB-04 |
| Auction operations | Synthetic load, kill switch, readiness checklist and incident drill | AUC-01 plus payment/legal readiness |
| Observability | Define structured events, redaction, dashboards-as-code and local alert fixtures | monitoring destination/retention |
| Clerk linking | Synthetic dual-proof/manual-review state machine only | ID-01 and legacy-system access |
| Bootstrap runbook | Dry-run with synthetic UUIDs in disposable DB | ID-02 and named real accounts |

Creating an external sandbox account, adding any secret, sending a message, uploading a real document, creating a provider payment object, applying a remote migration or toggling an operational feature requires its specific approval.

## Phase blockers

| Decision | Phase 6B effect | Phase 7 effect |
|---|---|---|
| DB-01/02/04 | Blocks real persistence and database-backed adapters | Blocks all protected commerce |
| PAY-01/02/03 | Blocks provider payment flow | Blocks checkout/payment release |
| REF-01 | Blocks refund execution | Blocks compliant cancellation/refund operations |
| SET-01 | Blocks transfer execution | Blocks seller payout operations |
| COM-01 | Blocks intermediary commission execution | Blocks commission settlement |
| MSG-01/02 | Blocks real invitation/commerce email | Blocks operational communication release |
| MED-01/02 | Blocks real private uploads | Blocks private documents and certificate files |
| CERT-01 | Blocks public certificate verification | Blocks verification release |
| AUC-01 | Blocks live-auction implementation/activation only | Blocks any live auction |
| ID-01 | Does not block ordinary Phase 6B adapters | Blocks legacy-user continuity if required |
| ID-02/03 | Blocks privileged development administration after DB apply | Blocks secure production operations |
| OPS-01/PROD-01 | Does not block local development | Blocks production financial operations/deployment |

## Recommended approval sequence

1. Approve DB-01 supersession and commission a final human SQL review.
2. Approve Phase 3 policy decisions: Finance prohibition, representation scope/revocation, suspension/session revocation and development bootstrap.
3. Approve final Phase 3 migrations, fresh rehearsal and a development apply window.
4. Approve Phase 6A domain migration shape; decide whether to split it; rerun against post-Phase-3 schema.
5. In parallel, approve provider evaluation and development sandboxes for payment, email and private media.
6. Approve core commercial rules (PAY-03, REF-01, SET-01, COM-01) before provider transaction creation.
7. Approve certificate disclosure and notification consent before public/message activation.
8. Treat live auctions as a separate program after payment, refund, reconciliation and incident controls are proven.
9. Complete PROD-01 as a Phase 7 release review; do not promote development approvals automatically.

## Production deployment prerequisites

Phase 7 release readiness requires documented evidence for:

- final production schema diff, migrations, backup/restore and rollback rehearsal;
- production Supabase and Cloudflare environment isolation;
- two production Super Admins with MFA and recovery procedure;
- approved secrets inventory, rotation schedule and named owners;
- provider live-account approval, DPA/compliance and callback allowlists;
- domain, DNS, TLS, sender authentication and CSP/security headers;
- monitored queues/workers, dead-letter processing, database/provider alerts and on-call ownership;
- payment/refund/settlement/commission reconciliation and segregation of duties;
- privacy notices, terms, cookie/consent, retention, DSAR and breach procedure;
- private-media scanning, legal holds, access review and incident response;
- certificate issuer/disclosure/revocation policy;
- auction-specific approval if auctions are in release scope;
- accessibility, responsive, performance, security, RLS, load and disaster-recovery tests;
- no staged-data promotion unless separately approved and validated;
- explicit go/no-go and rollback authority.

## Readiness conclusion

Phase 6B can safely start with local/disposable provider adapters, test harnesses and final migration review. It cannot create real provider objects or persist new commerce workflows until the relevant approvals are recorded. Phase 7 remains blocked by database rollout, privileged-access procedures, commercial/legal rules, production providers, monitoring and release sign-off.
