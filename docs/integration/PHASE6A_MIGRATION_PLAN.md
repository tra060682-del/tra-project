# Phase 6A additive migration plan

## Baseline and compatibility

Read-only inspection on 17 November 2026 confirmed exactly **39 public tables** in development, seven applied repository migrations ending `202611130002`, no Phase 1/3 draft objects, and the previously imported `emergent_staging.id_map` at 400 rows. No staged record was read into the application or promoted. No remote mutation was performed.

`202611170101_phase6a_commerce.draft.sql` is an approval-gated proposal, not an applied migration. It requires the current baseline followed by the approved Phase 3 RBAC migration. The earlier broad Phase 1 commerce design and any historical `202611140103` draft are superseded for commerce by this file; they must not be applied together.

## Dependency order

1. Preserve/verify the 39-table baseline and seven applied migrations.
2. Approve and apply Phase 3 authorization functions and RLS after its separate review.
3. Set the disposable/approved execution guard `app.tra_phase6a_target`.
4. Apply `202611170101_phase6a_commerce.draft.sql` transactionally.
5. Run `202611170190_phase6a_verify.draft.sql` and database security/concurrency tests.
6. Keep all operational feature flags disabled.
7. Configure external services only in Phase 6B after separate approval.

## Proposed changes

The proposal additively extends seven existing aggregates (`buyers`, `sales`, `settlements`, `shipments`, `certificates`, `artist_representations` and their supporting relationships) and adds **22 tables**: wishlist/recent/bag (4), offers/reservations (3), payment/refund/ledger (5), commission/settlement/shipment/certificate histories (4), notifications (3), private media/audit (2), and operational exceptions (1).

It adds indexes, foreign keys, check/unique constraints, 17 read policies, two immutable triggers, and 11 narrowly scoped RPCs. It grants authenticated execution only on user/operational RPCs, anonymous execution only on the disclosure-safe certificate verifier, and ledger posting only to `service_role`. Direct table writes remain revoked.

No PostgreSQL enum is added in Phase 6A; statuses are checked text, so rollback is not blocked by irreversible enum values. Phase 3 enum additions retain their previously documented rollback limitation.

## Rehearsal results

`npm run test:phase6a-database` restored the current remote schema-only dump into disposable local Supabase and passed:

- target guard and dependency checks;
- forward migration over all 39 tables;
- table, constraint, index, RLS, policy, grant and RPC verification;
- anonymous denial, ownership, suspension and role boundaries;
- offer state/version and concurrent acceptance protection;
- one-active-reservation protection;
- payment idempotency and provider-event uniqueness;
- balanced ledger posting and immutable finance records;
- disclosure-safe certificate verification;
- Finance auction exclusion;
- rollback and restoration to exactly 39 public tables.

No customer data was copied. The temporary schema-only dump is deleted before commit.

## Rollback

`202611170199_phase6a_rollback.draft.sql` first revokes/drops RPCs and policies, removes triggers and new tables in dependency order, then removes only Phase 6A columns/constraints from existing aggregates. `phase6a_rollback_verify.sql` proves absence of new objects and exact baseline table count. Rollback discards Phase 6A data, so a real rollout requires an encrypted export and finance reconciliation before rollback approval.

## Approval gates

Database/security owners must approve dependency order, RLS, grants, RPC ownership, backup/restore, downtime and rollback. Finance/legal/product must approve monetary, tax, refund, settlement, commission, certificate and shipping rules. None has been inferred from preview data.

