# Phase 6A.5 approval register

## Purpose and decision convention

This register consolidates the unresolved decisions from Phases 3.5, 5 and 6A. It authorizes nothing by itself. No migration, provider configuration, payment, email, auction, deployment or production change may be inferred from a recommendation.

Complexity estimates describe implementation after approval: **S** (up to two engineering days), **M** (roughly three to five days), **L** (one to two weeks), and **XL** (multi-system or multi-week). They are planning bands, not delivery commitments.

“Blocks 6B” means it prevents the related external-service integration or transactional workflow. “Blocks 7” means it prevents production release even if sandbox work can continue.

## Database and Supabase

### DB-01 — Canonical baseline and superseded drafts

- **Recommended option:** formally accept the verified 39-public-table development baseline. Mark `202611140101_phase1_permissions_and_identity.draft.sql` historical and never applicable. Mark `202611140103_phase1_commerce_finance_auction.draft.sql` superseded by the Phase 6A commerce proposal; never apply both.
- **Alternatives:** rebuild a new consolidated baseline migration after a full schema diff; or retain every historical draft and manually resolve collisions. The latter is not recommended.
- **Security implications:** applying superseded drafts would duplicate authority functions, grants and finance structures with incompatible definitions and could broaden access.
- **Complexity:** S for approval and immutable migration manifest; L for a full baseline rebuild.
- **Required user approval:** explicit database-owner approval of the baseline and supersession list.
- **Blocking:** blocks Phase 6B database application; blocks Phase 7 release evidence.

### DB-02 — Phase 3 RBAC migration sequence

- **Recommended option:** promote the rehearsed role-enum and Phase 3 RBAC drafts into immutable, ordered migrations after a fresh schema-only rehearsal and human SQL review. Apply to development in a separately approved maintenance window before Phase 6A.
- **Alternatives:** keep application-only authorization; or replace the proposal with a new RBAC design. Application-only authorization is insufficient for commerce.
- **Security implications:** provides active-account denial, multiple-role permissions, protected-permission rules, representation scope, invitation controls and audit enforcement. Rollback retains additive enum labels.
- **Complexity:** L, including rehearsal, review, development apply and post-apply tests.
- **Required user approval:** explicit approval to create final migration files and separately to apply them to development. Production requires another approval.
- **Blocking:** blocks Phase 6B transactional persistence and all Phase 7 protected commerce.

### DB-03 — Catalogue/content proposal

- **Recommended option:** review `202611140102_phase1_catalogue_content_operations.draft.sql` as an independent content migration, apply only the still-required additive objects, and exclude any identity or commerce overlap.
- **Alternatives:** defer it until content editing is prioritized; or replace it with smaller domain migrations.
- **Security implications:** a smaller migration reduces blast radius. Legal/content publication must remain versioned and permission controlled.
- **Complexity:** M to split and rehearse; L if applied as a broad migration.
- **Required user approval:** product and database-owner approval of the included content capabilities.
- **Blocking:** does not block payment-oriented Phase 6B; blocks Phase 7 content administration if those capabilities are in release scope.

### DB-04 — Phase 6A commerce migration

- **Recommended option:** apply the 22-table additive proposal only after DB-02, after a new schema-only rehearsal against the then-current development schema. Preserve disabled server flags after application.
- **Alternatives:** split into catalogue-commerce, finance, fulfilment and notification migrations; or defer all persistence. Splitting is safer operationally but adds review/rehearsal overhead.
- **Security implications:** activates RLS, constrained grants, transactional offer/reservation RPCs, idempotency, immutable finance, disclosure-safe certificates and private-media metadata. Applying it without Phase 3 intentionally fails.
- **Complexity:** L as one reviewed package; XL if split and independently rolled out.
- **Required user approval:** database/security approval for final SQL, development window, backup, rollback owner and post-apply verification.
- **Blocking:** blocks most Phase 6B integrations; blocks Phase 7 commerce release.

### DB-05 — Migration rollback and data-retention procedure

- **Recommended option:** permit rollback only after encrypted export of Phase 6A records and completed finance reconciliation; use the rehearsed rollback in dependency order and verify restoration to the approved baseline.
- **Alternatives:** forward-fix only; or destructive rollback without export. Destructive rollback is unacceptable once commerce data exists.
- **Security implications:** prevents loss of audit, payment, certificate and ledger evidence. Backup access must be tightly controlled and logged.
- **Complexity:** M for runbook and rehearsal; L after live data exists.
- **Required user approval:** database owner, security and finance approval.
- **Blocking:** does not block sandbox adapter development; blocks Phase 7 production migration.

## Payments, refunds, settlements and commissions

### PAY-01 — Payment provider and credential boundary

- **Recommended option:** retain the provider-neutral adapter and use a single sandbox provider first. Razorpay is the preferred initial candidate because the authoritative Emergent contract already models its identifiers and INR flow, subject to legal-entity, geography, commercial and compliance validation. If it is unsuitable, use Stripe through the same adapter.
- **Alternatives:** Stripe first; bank-transfer-only pilot with manual reconciliation; or no payment collection. Bank transfer reduces API scope but increases operational and reconciliation risk.
- **Security implications:** credentials must be server-only; required values are sandbox key/account identifier, secret, webhook signing secret and permitted webhook origin/endpoint configuration. Production credentials must be separate, rotated and stored as Cloudflare secrets. Browser redirects never prove payment.
- **Complexity:** L for one provider sandbox; XL for multiple providers.
- **Required user approval:** provider selection, procurement/DPA, test-account creation and permission to configure sandbox credentials.
- **Blocking:** blocks payment integration in Phase 6B and payment activation in Phase 7.

### PAY-02 — Payment confirmation, replay and reconciliation policy

- **Recommended option:** mark paid only from a verified, idempotent server callback matching order, amount and currency; retain provider event identifiers and payload digests; reconcile daily and route mismatches to operational exceptions.
- **Alternatives:** scheduled provider polling as the primary confirmation path; or manual confirmation. Polling is a useful recovery path but should not replace signed events.
- **Security implications:** prevents forged redirects, replay and amount substitution. Define signing algorithm, maximum event age, duplicate retention and secret-rotation overlap.
- **Complexity:** L.
- **Required user approval:** security and finance approval of callback/reconciliation controls.
- **Blocking:** blocks Phase 6B payment completion and Phase 7 money movement.

### PAY-03 — Tax, fee and currency policy

- **Recommended option:** launch with one settlement currency per order, immutable price snapshots, integer minor units and basis-point fees. Obtain tax advice before calculating or displaying tax as final; until then label estimates and disable checkout.
- **Alternatives:** tax-inclusive catalogue prices; tax-exclusive calculation by jurisdiction; or manual invoicing for the pilot.
- **Security implications:** prevents mutable historical totals and floating-point errors. Incorrect tax configuration creates legal and financial exposure rather than only a technical defect.
- **Complexity:** M technically; potentially L/XL for legal and multi-jurisdiction rules.
- **Required user approval:** product, finance and legal approval of currency, tax, buyer premium and platform commission.
- **Blocking:** blocks checkout/payment Phase 6B; blocks Phase 7 commerce release.

### REF-01 — Refund and cancellation policy

- **Recommended option:** allow staff-requested refunds only, with documented reason, amount bounded by captured less prior/pending refunds, two-person approval above an approved threshold, and provider execution from a background worker. Use compensating ledger entries.
- **Alternatives:** automatic buyer self-service within a fixed window; provider-dashboard-only refunds; or no refunds. Provider-dashboard-only action creates audit drift unless imported.
- **Security implications:** limits unauthorized or duplicate refunds and preserves accounting history. Threshold, eligible states, shipping deductions and dispute treatment must be explicit.
- **Complexity:** L.
- **Required user approval:** legal/finance/product approval of eligibility, windows, thresholds and allocation.
- **Blocking:** blocks refunds in Phase 6B; unresolved refund terms block Phase 7 checkout.

### SET-01 — Artist settlement policy

- **Recommended option:** calculate payable from immutable sale/ledger evidence, place it on hold until verified payment plus delivery/return conditions, require Finance preparation and independent approval, and initially execute transfers manually with recorded external reference.
- **Alternatives:** automated payout provider; payout immediately after payment; or periodic manual invoice settlement. Immediate payout is not recommended because refunds and delivery failures remain possible.
- **Security implications:** enforce segregation of duties, protect bank details in a dedicated compliant processor, and never derive banking data from profiles.
- **Complexity:** L for controlled manual settlement; XL for automated payouts/KYC.
- **Required user approval:** finance/legal approval of cadence, hold/release, adjustments, disputes, bank-data processor and approval threshold.
- **Blocking:** blocks settlement execution in Phase 6B; blocks Phase 7 settlement release.

### COM-01 — Intermediary commission entitlement

- **Recommended option:** entitlement is created only when an approved, artist-consented representation with explicit settlement scope is active at the binding sale event. Freeze the agreement/rule snapshot at that event; later revocation removes access but does not erase already-earned entitlement unless the agreement expressly says otherwise.
- **Alternatives:** determine entitlement at payment capture, at fulfilment, or manually per sale; cancel all unpaid entitlement on revocation. Each alternative needs contractual wording.
- **Security implications:** avoids granting money merely from visibility and prevents retrospective rule changes. Percentage/fixed basis, rounding, tax, refunds and split adjustments must be immutable and auditable.
- **Complexity:** M technically; L with agreement/version work.
- **Required user approval:** legal/product/finance approval of the binding event, post-revocation treatment and calculation rules.
- **Blocking:** blocks commission activation in Phase 6B and any intermediary settlement in Phase 7.

## Email and notifications

### MSG-01 — Transactional email provider and outbox worker

- **Recommended option:** implement a provider-neutral, server-only outbox worker and select one transactional provider after procurement. Postmark is the preferred pilot candidate; AWS SES or Resend are acceptable alternatives if their DPA, regional, deliverability and operational requirements fit better.
- **Alternatives:** Supabase Auth mail only for identity messages plus a separate transactional provider; direct synchronous sending; or no outbound email. Synchronous sending is not recommended.
- **Security implications:** required credentials are provider API token, verified sender/domain configuration, signing secret for delivery callbacks and DNS records. Plain invitation/reset tokens must never be logged. Retry uses stable idempotency keys.
- **Complexity:** L including domain verification, worker, callbacks and monitoring.
- **Required user approval:** provider, DPA, sender identity, DNS changes and sandbox credential configuration.
- **Blocking:** blocks invitation and transactional email in Phase 6B; blocks Phase 7 account operations unless a compliant alternative exists.

### MSG-02 — Notification preferences and mandatory messages

- **Recommended option:** separate in-app and email preferences by category; default marketing off; permit users to opt out of optional updates; do not permit opt-out from essential security, legal, payment and order messages. Retain delivery metadata, not unnecessary message payloads.
- **Alternatives:** global opt-in/out; all transactional messages mandatory; or in-app only.
- **Security implications:** supports consent and avoids suppressing security events. Retention, localization, quiet hours and sensitive data in subject lines require policy.
- **Complexity:** M.
- **Required user approval:** product/legal approval of mandatory categories, retention and consent text.
- **Blocking:** does not block a local outbox implementation; blocks Phase 6B real delivery and Phase 7 notification compliance.

## Private media and certificates

### MED-01 — Private storage provider and access model

- **Recommended option:** keep the 26 approved public artwork files on the approved public-media path/Cloudinary contract, and use a separate private Cloudflare R2 bucket for legal, identity, certificate, order and shipping documents. Access only through short-lived signed server responses after ownership/permission checks.
- **Alternatives:** Cloudinary authenticated/private assets for both; Supabase private Storage; or another object store. A permanent public URL is not an option.
- **Security implications:** required secrets include R2 account ID, bucket, scoped access-key ID/secret and signing configuration. Use separate development/production buckets, opaque object keys, encryption, access audit, revocation and least-privilege lifecycle permissions.
- **Complexity:** L.
- **Required user approval:** storage provider, region/DPA, retention, signed-link lifetime, size/type limits and sandbox credentials.
- **Blocking:** blocks private uploads in Phase 6B; blocks Phase 7 legal/certificate document release.

### MED-02 — Malware scanning and document retention

- **Recommended option:** quarantine every private upload until asynchronous scanning reports clean; reject mismatched MIME/signature and dangerous archives; retain digest and scan evidence; use purpose-specific retention and legal holds.
- **Alternatives:** managed scanning service, isolated ClamAV worker, or provider-native scanning. No scanning is acceptable only for a development fixture bucket with synthetic files and no public access.
- **Security implications:** unscanned documents can attack staff browsers or downstream systems. Scanner credentials and callbacks must be scoped and authenticated.
- **Complexity:** L/XL depending on managed versus self-hosted scanning.
- **Required user approval:** scanner/provider, file policy, retention and incident procedure.
- **Blocking:** blocks real private-media ingestion in Phase 6B and production uploads in Phase 7.

### CERT-01 — Certificate verification disclosure

- **Recommended option:** retain the proposed high-entropy `tra_coa_` token, store only its SHA-256 hash, and disclose only reference code, artwork reference, artist display name, issue date, version, validity and revocation state. Do not disclose owner, seller contacts, order, price or file location.
- **Alternatives:** QR code containing the opaque token; authenticated-only verification; or public reference-number lookup. Public sequential/reference lookup is not recommended because it enables enumeration.
- **Security implications:** add edge/application rate limiting, generic not-found responses, token rotation on compromise, explicit revocation and immutable audit. Artist remains issuer; admin review cannot silently replace issuer.
- **Complexity:** M.
- **Required user approval:** legal/security approval of public fields, evidence standard, revocation/appeal policy, rate limits and issuer wording.
- **Blocking:** blocks public verification in Phase 6B and Phase 7 certificate release.

## Auctions and privileged operations

### AUC-01 — Auction launch and money controls

- **Recommended option:** retain preview-only auctions until a per-auction two-person launch approval confirms schedule, lots, reserve confidentiality, bidder eligibility, terms, support coverage, kill switch, incident owner, payment path and reconciliation readiness. Keep launch and bidding as independent server flags.
- **Alternatives:** global launch approval; invite-only pilot; or no live auctions. An invite-only pilot reduces scale but not financial-control requirements.
- **Security implications:** preserve PostgreSQL bid serialization/idempotency; never move correctness to application state. Finance-role identities remain prohibited from bidding, including multi-role accounts. Winner selection, payment and settlement must be independently audited.
- **Complexity:** XL.
- **Required user approval:** executive/product, legal, security and finance approval for pilot terms and each launch procedure.
- **Blocking:** does not block non-auction Phase 6B; blocks live-auction work in Phase 6B and any Phase 7 auction launch.

### OPS-01 — Exception handling and segregation of duties

- **Recommended option:** define severity, owner, SLA, evidence, resolution reason and independent approval for payment, refund, settlement, certificate and auction exceptions. No silent status edits; corrections use audited state transitions or compensating ledger entries.
- **Alternatives:** ticketing-system integration; database-only queue; or manual spreadsheet. A spreadsheet cannot be the authoritative financial control.
- **Security implications:** prevents one privileged user from creating, approving and concealing a financial change.
- **Complexity:** M for internal queue; L for ticketing integration.
- **Required user approval:** operations/security/finance approval of roles, thresholds and SLAs.
- **Blocking:** does not block local adapter development; blocks Phase 7 financial operations.

## Identity and bootstrap

### ID-01 — Clerk-to-Supabase identity linking

- **Recommended option:** keep Supabase Auth canonical and perform no automatic email match. Require proof of both accounts; preserve the Supabase UUID; store only a one-way legacy Clerk identifier plus evidence category; send ambiguous, changed-email and privileged cases to two-person manual review. Never migrate passwords, sessions or roles.
- **Alternatives:** email-only automatic linking; administrator CSV mapping; or no legacy linking. Email-only linking is unsafe. No linking is acceptable if users can create and verify new Supabase identities without losing required records.
- **Security implications:** prevents account takeover and privilege inheritance. Linking must be idempotent, audited, reversible by a controlled unlink process and unable to grant roles.
- **Complexity:** L/XL depending on Clerk export/API evidence.
- **Required user approval:** security/legal approval of proof rules, legacy data access, retention and exception handling.
- **Blocking:** does not block provider sandbox development; blocks Phase 7 migration of legacy users and any release requiring account continuity.

### ID-02 — Initial Super Admin bootstrap

- **Recommended option:** UUID-specific, two-person bootstrap in development only, after verified email and MFA. Create two independent Super Admin accounts, verify audit evidence and disable the bootstrap path. Use audited RPCs thereafter. Production uses a separate approved change.
- **Alternatives:** one break-glass administrator with sealed recovery; manual SQL by one operator; email allowlist. Email-based or single-operator bootstrap is not recommended.
- **Security implications:** prevents email impersonation and unreviewed privilege escalation. Recovery credentials, MFA factors and audit evidence must be held by separate people.
- **Complexity:** M including runbook and rehearsal.
- **Required user approval:** named account UUIDs, two approvers, MFA evidence, window and rollback; separate production approval.
- **Blocking:** blocks Phase 6B privileged development administration after migrations; blocks Phase 7 operations.

### ID-03 — Suspension/reactivation and session revocation

- **Recommended option:** make account-status change and Supabase Auth session revocation one audited operational workflow. Super Admin controls privileged/staff accounts; high-risk reactivation is two-person, requires fresh authentication and does not restore revoked roles or representations.
- **Alternatives:** database-only suspension; short token expiry without revocation; or delegated ordinary-user suspension.
- **Security implications:** database-only suspension is enforced by rehearsed RLS but leaves active Auth sessions until every operation rechecks status; explicit revocation reduces residual risk.
- **Complexity:** M.
- **Required user approval:** delegation rules, reviewer thresholds, support procedure and use of the server-only Supabase Admin API.
- **Blocking:** blocks Phase 7 secure operations; Phase 6B local work may proceed.

## Production release

### PROD-01 — Production deployment prerequisites

- **Recommended option:** require a formal release gate covering final migrations and backups; production Supabase/Cloudflare separation; least-privilege secrets; domain/DNS/TLS; monitoring and alerts; queue/worker health; provider sandbox-to-live approval; legal pages and consent; data retention/DSAR; support and incident runbooks; finance reconciliation; accessibility/performance/security regression; disaster recovery; and rollback ownership.
- **Alternatives:** limited closed pilot with allowlisted users and no money movement; or public read-only release. These reduce scope but do not waive privacy, identity or infrastructure controls.
- **Security implications:** development credentials, flags and data must never be promoted. Production secrets need rotation, audit and named owners. Database flags and provider capability must remain independently gated.
- **Complexity:** XL.
- **Required user approval:** executive/product, security, legal, finance, database and infrastructure release sign-off.
- **Blocking:** does not block Phase 6B sandbox development; blocks Phase 7 production deployment.

## Approval summary

The minimum approvals to begin meaningful Phase 6B persistence/provider work are DB-01, DB-02, DB-04 and the relevant domain decision: PAY-01/02/03 for payments, REF-01 for refunds, SET-01 for settlements, COM-01 for commissions, MSG-01/02 for email, MED-01/02 for private files, or CERT-01 for verification. AUC-01 is independent and should not delay non-auction commerce work.

No approval may be bundled into a generic “proceed” instruction. Migration application, sandbox credential configuration, production credential configuration, feature activation and production deployment are separate change decisions.
