# Phase 6B.1 migration ordering and rehearsal

## Remote read-only verification

On 14 November 2026, the user-designated development project `tra-development` (`ocstvctvmychromkcurw`) was inspected read-only. It still reported the same seven applied migrations ending `202611130002`, 39 public tables, empty baseline commerce tables and the existing `emergent_staging.id_map` estimate of 400. No Phase 3 or Phase 6A proposal was present and no staging row was promoted.

The Supabase CLI labels the primary branch of this project with environment metadata `production`; the project name/ref nevertheless matched the explicitly supplied development project. This discrepancy is recorded and no write was attempted. Production application infrastructure was not accessed or changed.

## Dependency sequence

The executable harness enforces:

1. current 39-table baseline;
2. `202611140100_phase1_role_enum.draft.sql`;
3. `202611150100_phase3_role_enum.draft.sql`;
4. `202611150101_phase3_auth_rbac.draft.sql`;
5. `202611170101_phase6a_commerce.draft.sql`;
6. Phase 6A verification/RLS/transaction tests;
7. Phase 6A rollback;
8. Phase 3 rollback and exact baseline verification.

`202611140101_phase1_permissions_and_identity.draft.sql` and `202611140103_phase1_commerce_finance_auction.draft.sql` are explicitly excluded as superseded. The optional Phase 1 catalogue/content draft is outside the commerce dependency chain.

## Disposable result

`npm run test:phase6b1-database` passed ten reported checkpoints:

- 39-table restore;
- target guard;
- forward dependencies;
- tables/RLS/grants/functions/immutability;
- ownership, offer/reservation concurrency, ledger, certificate and suspension controls;
- rollback to 39 tables;
- Phase 6B.1 dependency-order assertion;
- superseded-migration exclusion;
- no destructive forward operation assertion;
- enum-residue documentation assertion.

No remote migration execution or row data was used. The disposable stack was stopped without backup. Rollback is structurally complete for Phase 6A but Phase 3 role enum labels remain additive residue because safe PostgreSQL enum removal requires a rewrite. Therefore rollback is not claimed byte-for-byte reversible for enum types.

The 22-table Phase 6A migration remains a proposal. This rehearsal does not approve conversion into `supabase/migrations` or application to development/production.

