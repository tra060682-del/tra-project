# Phase 6A security review

## Controls implemented

| Threat | Control |
|---|---|
| IDOR/cross-user access | Server authorization plus ownership-scoped RLS and RPC predicates |
| Suspended account mutation | `tra_account_is_active` at policy/RPC boundary |
| Stale or duplicate offer acceptance | row locks, state version, expiry and terminal-state checks |
| Conflicting original reservations | advisory lock plus partial unique index |
| Payment replay | unique intent idempotency and provider event identifiers |
| Forged payment success | future signed server callback required; no browser confirmation contract |
| Ledger tampering | service-only posting, balance check, immutable trigger |
| Excess refund | sale lock and cumulative refundable-amount check |
| Commission overreach | sale + active representation agreement reference and snapshot |
| Certificate enumeration/disclosure | high-entropy token, stored hash, bounded public projection |
| Private document exposure | opaque private keys, no public URL, ownership RLS, access audit |
| Auction manipulation | existing PostgreSQL concurrency retained; live flag off; Finance cannot bid |

## Enforcement status

Application authorization is active for the new routes and actions. Feature flags fail closed. The proposed database controls passed an isolated Supabase/PostgreSQL rehearsal for anonymous denial, ownership isolation, suspension, offer/reservation conflicts, immutable finance, certificate disclosure and rollback. They are **not** active in development or production because the migration is unapplied.

The proposal depends on Phase 3 functions (`tra_account_is_active`, `tra_has_permission`, `tra_owns_artist`, representation checks). Phase 3 must be approved and applied first. Applying Phase 6A without that dependency is intentionally blocked.

## Residual risks and approvals

- Representation vocabulary and commission entitlement after revocation are unresolved.
- Provider webhook algorithms, replay window and secret rotation are unselected.
- Tax, refund, settlement and reconciliation policies need finance/legal approval.
- Certificate evidence, revocation appeal and public rate limiting need legal/security approval.
- Private storage, malware scanner and signed-link lifetime are unselected.
- Admin exception resolution and segregation of duties need an operating procedure.
- The first Super Admin bootstrap remains approval-gated.

No credential was added. The scan found only expected configuration variable names and the literal PostgreSQL role `service_role`; no credential value or private key is present.

