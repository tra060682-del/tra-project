# Phase 5 review

## Outcome

All five primary dashboard experiences are implemented on the Phase 2 design foundation. Current baseline workflows use real Supabase persistence and server authorization; unsupported workflows are accurately limited, preview-only or blocked. Curator, Art Advisor and Finance / Operations users share permission-aware modules instead of receiving duplicate dashboards.

## Functional summary

| Dashboard | Total | Fully Functional | Limited | Preview | Blocked |
|---|---:|---:|---:|---:|---:|
| Super Admin | 12 | 3 | 2 | 4 | 3 |
| Admin | 13 | 4 | 5 | 2 | 2 |
| Artist Studio | 13 | 7 | 4 | 0 | 2 |
| Intermediary | 9 | 3 | 1 | 1 | 4 |
| Collector | 12 | 3 | 3 | 1 | 5 |
| **Total** | **59** | **20** | **15** | **8** | **16** |

The row-level source of truth is `PHASE5_FEATURE_MATRIX.md`; totals describe user-facing capabilities, not files or API endpoints.

## Security and database status

- All dashboard routes authenticate server-side; current mutations re-authorize independently.
- Privileged or approval-dependent actions fail closed through server-only gates.
- No staging query, promotion, database migration or remote database mutation was performed.
- The exact baseline remains the Phase 3.5 **39 public tables**. Phase 0’s historical 40-table statement is superseded.
- The Phase 1/3 draft SQL remains unapplied. Therefore proposed suspension, representation-scope, invitation and new permission enforcement is not claimed at database level.
- 26 approved media files remain publishable; the 23 unresolved assets remain quarantined and were not copied into public media.

## Phase 6 readiness

Phase 6 can begin application work only after decisions and additive migrations are approved for offers/counteroffers, immutable payment ledger/provider integration, order transactions, disclosure-safe certificates, notifications/preferences, outbound email, collector-safe shipping projections, live-auction launch controls and financial reconciliation. Private media uploads additionally need a signed server-side Cloudinary/R2 contract.

## Outstanding approvals

1. Initial Super Admin bootstrap and Phase 3 database enforcement rollout.
2. Invitation delivery provider and verified acceptance lifecycle.
3. Clerk-to-Supabase identity linking rules (still approval-gated).
4. Intermediary scope vocabulary, expiry and revocation operational policy.
5. Legal approval for artist declarations, agreements and certificate disclosure.
6. Artwork-media rights evidence and signed upload/storage policy.
7. Offer expiry/counteroffer rules and reservation semantics.
8. Payment provider, ledger immutability, refunds, settlement and reconciliation.
9. Shipping privacy, courier integration and delivery confirmation.
10. Live-auction launch, bidder eligibility, finance exclusion and incident procedure.
11. Notification/email provider, consent, templates, retention and delivery logging.

Phase 5 stops here. No Phase 6 workflow was activated.
