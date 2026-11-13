# Additive migration design

Status: implementation design only. Draft SQL is deliberately outside `supabase/migrations`; it has not been applied, pushed, linted against the remote database, or approved for execution.

## Draft files

| Sequence | File | Purpose |
|---:|---|---|
| 202611140100 | `sql/202611140100_phase1_role_enum.draft.sql` | Add role enum values in a separate committed migration |
| 202611140101 | `sql/202611140101_phase1_permissions_and_identity.draft.sql` | Add roles, permission resolution, overrides and account-state foundation |
| 202611140102 | `sql/202611140102_phase1_catalogue_content_operations.draft.sql` | Extend catalogue/content/legal/audit and add analytics/notifications |
| 202611140103 | `sql/202611140103_phase1_commerce_finance_auction.draft.sql` | Add offers/payment events/ledger/bidder profile and extend sales/certificates/auctions |
| 202611140190 | `sql/202611140190_phase1_verify.draft.sql` | Read-only structural/security/invariant verification |
| 202611140199 | `sql/202611140199_phase1_rollback.draft.sql` | Development rollback design for Phase 1 additions only |

Every forward draft requires the session setting `app.tra_phase1_target=ocstvctvmychromkcurw:approved-development-only`; rollback uses a different explicit approval value. This is an additional guard, not approval to run them.

## Additive definition

For this plan “additive” means:

- no existing table, column, enum value, row, function or trigger is removed by a forward migration;
- no existing column is renamed, narrowed or repurposed;
- new nullable/defaulted columns preserve existing reads and writes;
- existing domain tables are extended instead of duplicated;
- new constraints are added `NOT VALID`, then validated after compatibility checks;
- new indexes use distinct names and support bounded access paths;
- security may be tightened, but existing legitimate workflows require regression tests first;
- staging records are not re-imported.

The taxonomy type check is the one planned constraint replacement: its accepted set is broadened to include `artform`, `collection` and `colour`; existing accepted values and rows remain valid. The final migration must capture and compare the original definition.

## Migration order and gates

### 1. Preflight

1. Confirm exact project ref and forbid the production ref.
2. Take fresh logical schema/data backups.
3. Capture hashes/inventories for existing tables, columns, constraints, policies, functions, grants, triggers, enum values and row counts.
4. Confirm local migration history equals development history.
5. Confirm staging remains 400 records/15 collections and has no API grants.
6. Rehearse on a disposable restored copy.

### 2. Roles and permissions

- Extend `tra_role` with `super_admin`, `finance`, `advisor`.
- Add `role_permissions` and `user_permission_overrides`.
- Add `tra_has_role` and `tra_has_permission` with fixed search paths and limited execute grants.
- Add account status to `profiles`.
- Replace direct role writes with a separately reviewed locked RPC.
- Bootstrap the first Super Admin only through an explicit, verified development-only operation; never by matching an unverified staging email.

Gate: all role/RLS tests pass, including last-Super-Admin, self-escalation and revoke-wins.

### 3. Catalogue/content operations

- Add source/reference fields to existing artist, artwork, taxonomy, content, legal and audit tables.
- Normalize artwork/artist taxonomy and content relationships.
- Add classification evidence, bookmarks, privacy-bounded analytics, notifications/preferences/delivery logs.
- Broaden taxonomy types without changing existing values.

Gate: public projections still expose only approved/published records and approved media; existing Phase 1 artist/intermediary flows pass unchanged.

### 4. Commerce/finance/auction

- Extend `sales` as the order aggregate.
- Add offers and append-only offer events.
- Add signed/idempotent payment events and immutable ledger entries.
- Extend certificates and bidder profiles.
- Extend hardened auctions/lots only with metadata/state fields; preserve bid RPC behaviour.

Gate: money/concurrency tests, RLS, webhook replay, ledger immutability and current auction suites pass.

### 5. Staging transformation (not yet authored for execution)

No transformation SQL may be finalized until the unresolved identity, auction grouping and certificate/order decisions in `PHASE1_REVIEW.md` are approved. The eventual script must:

1. Lock an integration advisory key.
2. Assert the exact final import run: 400 records, 15 collections, expected manifest/pseudonymisation policy.
3. Fingerprint every non-target schema and pre-existing public object.
4. Allocate/reuse UUIDs through `emergent_staging.id_map`.
5. Insert parent records in dependency order with `ON CONFLICT` only on stable source IDs.
6. Normalize arrays/relationships only when every reference resolves.
7. Keep users, bidder, legal acceptance, auction and certificate rows on hold where documented.
8. Preserve the five attribution-review flags and audit rows.
9. Explicitly reject embedded QA legal-version keys.
10. Reconcile counts, source IDs, relationships, monetary totals and status distributions in the same transaction.
11. Abort and roll back on any mismatch.

This is promotion of existing staging data, not a repeat staging import.

## Planned functions and RPCs

| Function/RPC | Transactional requirements |
|---|---|
| `tra_has_role`, `tra_has_permission` | Stable, security-definer, fixed search path, no caller-controlled SQL |
| `set_user_access` | Lock target and role population; protected permissions; no self-escalation; retain ≥1 active Super Admin; immutable audit event |
| `submit_offer` | Lock buyer/artwork pair; published/available artwork; positive paise; no self-dealing; event append |
| `respond_to_offer` | Lock offer/artwork; party/scope check; valid state transition; atomic accepted sale/reservation |
| `expire_offers_and_reservations` | Database time; skip locked; idempotent; append events |
| `ingest_payment_event` | Provider/event uniqueness; verified signature flag; exact amount/currency; lock sale; append balanced ledger; idempotent replay |
| `record_refund` | Collected-minus-refunded bound; append-only event/ledger; state update atomically |
| `mark_notifications_read` | Caller-owned IDs only; bounded array input |
| `publish_content_version` | Permission check; immutable published state; timestamp/actor/audit |
| Existing bid/close RPCs | Preserve and extend only after concurrency regression tests |

The drafts include structural and representative RPC SQL. Provider-specific payment ingestion, user-access management and full offer acceptance remain review-gated because their final state machines depend on unresolved operational decisions.

## Index strategy

- Partial unique source-ID indexes guarantee idempotent promotion.
- Party/time indexes support dashboards without unbounded scans.
- Open-offer and unread-notification partial indexes support operational queues.
- Provider event uniqueness is the primary webhook replay barrier.
- Ledger event/account uniqueness prevents duplicate accounting entries.
- Analytics roll-up index uses date/event/reference, not direct identifiers.
- Existing auction indexes and private proxy ceiling access remain unchanged.

## Foreign-key strategy

- All application identities reference `auth.users(id)` only after verified linking.
- Staging text identifiers resolve through `emergent_staging.id_map` before insert.
- Artist/artwork/taxonomy/content/sale relations require resolved parent UUIDs.
- Audit history uses additive text references where the historical actor/entity cannot safely map to a UUID.
- Certificate import remains on hold until its missing sale/order relationship is resolved.
- No foreign key points from public application tables back into `emergent_staging`.

## RLS strategy

- Default deny on every new table.
- Public reads only through published/approved projections.
- Owner policies compare to `auth.uid()`.
- Intermediary access requires an active approved representation plus the exact current scope.
- Staff access uses named permission predicates, not a generic Admin boolean.
- Payment events and ledger have no browser write policy.
- Analytics and delivery logs are permission-read-only.
- Staging retains no `anon`, `authenticated` or PUBLIC grants.

## Verification

The read-only verification draft must return zero issues. The rehearsal must additionally compare before/after hashes of all existing object definitions and rows, allow-listing only proposed additions. Required post-migration checks include:

- required tables, columns, roles, functions and policies present;
- RLS enabled;
- correct grants and function execute privileges;
- protected permissions held only by Super Admin;
- no staging exposure or record-count change;
- no negative money or invalid status rows;
- no unsigned processed payment;
- no orphan normalized relationship;
- existing artist/intermediary/auction/security tests unchanged;
- rollback restores the captured preflight inventory except retained enum values and evidence that cannot safely be destroyed.

## Rollback

Rollback is development-only and approval-gated. It removes Phase 1-created tables/functions and added columns after a backup. It never drops or changes `emergent_staging`. Added PostgreSQL enum values are retained because removing enum values safely requires a type rebuild and is not justified. If any post-migration production-like evidence existed, rollback would preserve it and use a forward corrective migration instead of dropping it.

## Promotion to real migrations

Before any draft can move to `supabase/migrations`:

1. Resolve the open decisions in `PHASE1_REVIEW.md`.
2. Complete every placeholder/representative RPC.
3. Review SQL for policy recursion, function grants and state transitions.
4. Run formatting/lint/static destructive-target scans.
5. Rehearse forward, verification and rollback on a disposable dump.
6. Obtain explicit approval for development application only.
