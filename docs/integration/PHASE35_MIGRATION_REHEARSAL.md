# Phase 3.5 migration rehearsal

Status: PASS in an isolated disposable database. No remote migration was executed.

## Environment and evidence

On 2026-11-14 (Pacific/Auckland), the development project `ocstvctvmychromkcurw` was accessed read-only to create a `public` schema-only dump. The dump contained definitions and ACLs only—no `COPY`, table rows, credentials, or customer information. It was restored into a local Supabase PostgreSQL 17 container with automatic migrations disabled. The container was destroyed with `supabase stop --no-backup` after every run, and the temporary dump was securely removed from the workspace.

The exact development inventory is **39 public tables**, not 40. The “40-table public foundation” statement in Phase 1 is therefore superseded for public-schema counts. Auth-managed tables are outside this count. This discrepancy does not indicate a removed table; the schema dump and checked-in migration reconstruction both produced the same 39-table public foundation.

## Approved rehearsal sequence

The coherent candidate sequence tested was:

1. Existing development schema-only foundation.
2. `202611140100_phase1_role_enum.draft.sql`.
3. `202611150100_phase3_role_enum.draft.sql`.
4. `202611150101_phase3_auth_rbac.draft.sql`.
5. `202611140102_phase1_catalogue_content_operations.draft.sql`.
6. `202611140103_phase1_commerce_finance_auction.draft.sql`.

`202611140101_phase1_permissions_and_identity.draft.sql` is historical and explicitly superseded. Applying it with Phase 3 would duplicate account-status, permission-table and helper-function ownership with incompatible definitions.

## Corrections made during rehearsal

- Replaced the nonexistent `staff_role` dependency with the real `public.tra_role` enum.
- Made all approval guards fail closed with `IS DISTINCT FROM`; the previous `NULL <> expected` expression failed open.
- Corrected auction guard table names to `auction_proxy_bids` and `auction_bid_requests`.
- Added database enforcement preventing Finance / Operations actors from bidding.
- Added active-account checks to offer submission and restrictive authenticated policies so suspended users lose private reads as well as writes.
- Added Advisor enquiry, Finance sales/audit, and permission-based read policies without replacing legacy policies.
- Made protected permissions (`roles.manage`, `settings.manage`, `integrations.manage`) immune to non-Super-Admin overrides.
- Replaced inherited broad default privileges on every new Phase 1 table with explicit least-privilege grants.
- Added active-account guards to additive content, notification, offer, payment and ledger tables.
- Corrected Phase 1 and Phase 3 rollback dependency order.
- Made the schema-only restore reproduce source ACLs rather than local Supabase image defaults.

## Structural results

| Check | Result |
|---|---|
| Development schema-only restore | PASS — 39 public tables |
| Target guard without approval setting | PASS — rejected before mutation |
| Forward migration | PASS — 39 to 56 public tables |
| Existing tables retained | PASS |
| Existing columns/types/defaults retained | PASS |
| Existing constraints retained byte-for-byte | PASS |
| Existing policy definitions retained | PASS |
| Existing grants retained; none broadened | PASS |
| Existing function and trigger definitions retained | PASS |
| New-table RLS enabled | PASS |
| Enum scripts rerunnable | PASS |
| Main migrations rerunnable | Not intended; policies make them one-shot versioned migrations |
| Rollback | PASS — 56 to 39 public tables |
| Rollback baseline preservation | PASS |

Rollback intentionally retains added enum labels because safe PostgreSQL enum-value removal requires a type/table rewrite. This is additive residue, not an authority grant.

## Reproduction

The committed harness is `npm run test:phase35-database`. By default it reconstructs the schema from checked-in migrations. For an approved schema-only snapshot, set `PHASE35_BASELINE_DUMP` to the local dump path. The harness contains no remote push, linked migration, or deployment operation.

