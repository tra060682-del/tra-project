# Phase 1 review

Status: documentation and design complete; implementation is paused before Phase 2. No application code or database structure has changed.

## 1. Endpoint coverage

- Historical reported count: 128.
- Authoritative business route operations found in source: **214**.
- Crosswalk rows: **214/214**.
- Unaccounted source business operations: **0**.
- Clerk compatibility routes documented separately: 2; both retired under Supabase Auth.
- Exported OpenAPI operations: 89; marked superseded.

The difference is not newly added scope: the 128 audit count omitted decorators on `admin_router` and `users_router`. Each operation now records method, route, authentication/permission, request/response schema reference, database dependencies, business-rule/error code, current Next.js parity, migration approach and test classes.

## 2. Data mapping coverage

- Staged collections: **15/15**.
- Verified records: **400/400**.
- Observed source field paths: **319/319** accounted for in `DATABASE_FIELD_CROSSWALK.md`.
- Staging re-imports performed: **0**.
- Development database writes: **0**.

Ready/extend/normalize mappings exist for catalogue, content, taxonomy, legal, settings, analytics, audit and delivery history. Identity-dependent and relation-incomplete records are intentionally marked `hold`, not forced into invalid targets.

## 3. Required schema changes

The target reuses the existing 40-table public foundation. Proposed additive work is:

1. Add `super_admin`, `finance` and `advisor` roles plus named permissions/overrides and account state.
2. Extend artist, artwork, taxonomy, content, legal and audit tables with source/reference and workflow fields.
3. Normalize artist/artwork taxonomy, classification evidence and content relations.
4. Add offers/offer events, payment events, immutable ledger and bidder profile.
5. Extend sales as orders; do not create a duplicate orders aggregate.
6. Add notifications/preferences/delivery logs and privacy-bounded analytics.
7. Extend certificates and hardened auction tables without replacing current concurrency RPCs.

Versioned guarded SQL drafts, read-only verification and rollback design are under `docs/integration/sql`. They are not executable approvals and are deliberately absent from `supabase/migrations`.

## 4. Security risks

Highest-priority risks:

- Account takeover from email-only Clerk→Supabase linking.
- Privilege escalation through broad legacy Admin policies or direct role writes.
- Intermediary action after scope/relationship revocation.
- Loss of auction integrity if Mongo/application bidding replaces PostgreSQL locks and idempotency.
- Browser or webhook mutation of payment/ledger state without signature and replay checks.
- Public leakage of identity, bank, certificate original, proxy ceiling, notification or staging data.
- Treating pseudonymised attribution placeholders as real reviewers.
- Migrating embedded `tscheck_*`/`v2test_*` configuration keys.

The RBAC contract requires database enforcement, revoke-wins semantics, a last-Super-Admin guard, scoped representation, append-only evidence and per-role/cross-user tests.

## 5. Unresolved design decisions

Approval is required for:

1. The verified identity-linking process for the three staged Clerk users; no passwords may migrate.
2. Which verified account becomes the first Super Admin and the controlled bootstrap procedure.
3. How the nine staged auction lot-like documents are grouped into auction parents and which approved terms version/creator applies.
4. Whether the staged certificate should be retained as historical-only or linked after its missing sale/order is reconstructed.
5. Final offer states, reservation timeout and whether an accepted offer creates one sale automatically.
6. Payment provider, webhook event contract, refund rules and ledger chart of accounts.
7. Legal audience model and final approved legal content.
8. Analytics retention period and salt/visitor-hash rotation policy.
9. Email provider, retry limits and delivery-log retention.
10. Rights/credit approval for all 49 archived images.
11. Whether the current vertical brand rail remains or the approved Emergent glass header fully replaces it.
12. Whether dark theme is in scope; the approved baseline is light.

## 6. Readiness to begin implementation

**Conditionally ready for Phase 2 foundation work, not ready for data promotion or operational integrations.**

Safe after approval:

- Design-token/font/component foundation.
- Visual golden capture and regression harness.
- Final SQL review and disposable-database rehearsal.
- Permission helper implementation and tests on development fixtures.

Not ready:

- Staging-to-public transformation.
- Identity linking.
- Auction record promotion.
- Certificate promotion.
- Payments, real-money bidding, email sending, Cron deployment or AI enablement.
- Any production operation.

## Validation summary

| Gate | Result |
|---|---|
| Export checksums | PASS — 388/388 |
| Source endpoint coverage | PASS — 214/214; historical undercount corrected |
| Staged collection coverage | PASS — 15/15 |
| Staged record coverage | PASS — 400/400 |
| Additive-only forward design | PASS at design review; drafts still require SQL/rehearsal review |
| Existing Supabase state unchanged | PASS — before/after schema dump SHA-256 identical |
| Production untouched | PASS |
| Credentials in documentation | PASS — names/public refs only; no values |
| Application functionality unchanged | PASS |
| Deployment/merge | Not performed |

Stop condition reached: wait for explicit approval before Phase 2 application work or any database migration preparation beyond the draft/rehearsal stage.
