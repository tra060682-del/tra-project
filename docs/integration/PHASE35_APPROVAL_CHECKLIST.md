# Phase 3.5 approval checklist

## Migration package

- [ ] Accept the corrected 39-public-table development baseline and supersede the Phase 1 “40 public tables” statement.
- [ ] Confirm `202611140101_phase1_permissions_and_identity.draft.sql` remains historical and must not be applied.
- [ ] Review the five-file coherent forward sequence in `PHASE35_MIGRATION_REHEARSAL.md`.
- [ ] Approve restrictive active-account policies for authenticated private access.
- [ ] Approve Advisor enquiry and Finance sales/audit visibility.
- [ ] Approve the permanent Finance bidding prohibition.
- [ ] Accept one-shot main migrations and enum-only repeatability.
- [ ] Accept retained enum labels after rollback.
- [ ] Schedule a fresh schema-only rehearsal immediately before any development apply.

## Operational security decisions

- [ ] Approve dual-proof/manual-review identity linking rules.
- [ ] Approve the two-person, UUID-specific development Super Admin bootstrap.
- [ ] Approve the requirement for two initial Super Admin accounts and MFA.
- [ ] Select an invitation email provider and approve the server-only outbox design.
- [ ] Approve intermediary consent, scope, expiry and immediate-revocation rules.
- [ ] Approve session revocation and two-person high-risk reactivation procedures.

## Required evidence before development apply

- [x] Exact development public schema restored without rows.
- [x] Existing structural inventory preserved.
- [x] All eight roles tested at the database boundary.
- [x] Anonymous, cross-user and privilege-escalation denials tested.
- [x] Auction concurrency and Finance conflict tested.
- [x] Offer, payment, ledger and audit protections tested.
- [x] Forward migration and rollback passed.
- [x] Disposable stack destroyed; temporary schema dump removed.
- [ ] Human SQL review completed.
- [ ] Development maintenance window and rollback owner assigned.
- [ ] Explicit approval to convert reviewed drafts into immutable `supabase/migrations` files.

## Release boundary

Phase 4 application work may begin after product/security decisions are approved. Database application remains a separate approval. No production deployment, production migration, main merge, payment enablement, live-auction enablement or staging-record promotion is authorised by this checklist.
