# Phase 6A review

## Outcome

Phase 6A delivers the provider-independent, fail-closed commerce and operational foundation: shared contracts and calculations, server authorization/feature gates, five-dashboard integration, 22-table additive migration proposal, transactional RPCs, isolated security rehearsal, rollback, automated tests and activation documentation. No migration, staging promotion, deployment, payment, email, transfer, courier request or live auction was performed.

## Functional status

| Category | Functional with Limitations | Preview Only | Blocked | Reason |
|---|---:|---:|---:|---|
| Collector catalogue commerce | 0 | 4 | 1 | wishlist/recent/bag/offers need migration; checkout needs finance approval |
| Offers and reservations | 0 | 2 | 0 | transactional proposal is rehearsed but unapplied |
| Orders and fulfilment | 2 | 0 | 1 | real baseline reads; write lifecycle/checkout gated |
| Payments, refunds and ledger | 0 | 2 | 2 | provider absent; finance migration unapplied |
| Settlements and commissions | 1 | 1 | 0 | existing settlement reads; execution disabled |
| Certificates and private media | 1 | 0 | 2 | baseline certificate reads; verifier/storage gated |
| Notifications and operations | 1 | 3 | 2 | auction preview remains safe; delivery/providers absent |
| **Total** | **5** | **12** | **8** | See feature matrix for row-level authority |

No new Phase 6A user workflow is claimed Fully Functional while its database enforcement is unapplied.

## Database readiness

- Existing development baseline: 39 public tables; seven repository migrations applied.
- Staging: the established 400-row ID map remains untouched and unpromoted.
- Proposal: 22 new tables plus additive columns/constraints/indexes/RLS/RPCs on existing commerce aggregates.
- Compatibility: forward migration passed against a schema-only copy of the current baseline.
- Security: RLS/grants, suspension/ownership, concurrency, idempotency, immutability and disclosure tests passed.
- Rollback: passed and restored exactly 39 public tables.
- Approval: Phase 3 database dependency and Phase 6A proposal remain unapplied.

## Security

All dashboard routes authenticate server-side and new actions independently enforce active account, permission/scope, server flag and validated input. Offer/reservation mutations are transactional. Financial journal and provider events are immutable. Certificate verification is high-entropy and disclosure-safe. Private media is private-key based with audit and scan hooks. Finance users remain unable to bid. Database-level enforcement is demonstrated only in the isolated rehearsal, not claimed in development/production.

## Phase 6B readiness

Phase 6B may begin only after selecting and approving: payment/refund provider and webhook operations; transactional email and delivery worker; private Cloudinary/R2 plus malware scanner; background job/queue platform; monitoring, alerting and reconciliation; optional courier provider. Test/sandbox credentials must be server-only, with secret rotation and incident runbooks.

## Outstanding approvals

1. Phase 3 RBAC/RLS rollout and initial Super Admin bootstrap.
2. Phase 6A additive migration, grants, backup and rollback window.
3. Offer, counteroffer, expiry, cancellation and reservation rules.
4. Tax, currency, premium, refund, reconciliation and accounting treatment.
5. Settlement cadence, payout provider, bank-data handling and segregation of duties.
6. Intermediary entitlement when representation expires/revokes after a sale.
7. Shipping privacy, address retention, delivery proof and exception ownership.
8. Artist-issued certificate evidence, public fields, revocation and rate limiting.
9. Private storage, file limits, malware scanning and signed-link lifetime.
10. Notification consent, mandatory security messages, templates and retention.
11. Auction launch procedure, bidder eligibility and incident response.
12. External provider procurement, data processing terms, monitoring and production activation.

Phase 6A stops here. Phase 6B, migration application, deployment and production activation require explicit approval.

