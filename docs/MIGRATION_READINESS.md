# Artist authentication migration readiness

## Decision: GO

Assessment date: 10 November 2026.

`202611090001_artist_auth.sql` passed static compatibility review and a complete forward/verify/security/rollback rehearsal on a disposable local Supabase stack. This GO applies to the migration itself under a controlled, backed-up production change procedure. It does not authorize production execution, `supabase db push`, merging, or deployment.

## Predeployment drift check

The predeployment export `docs/database-inventory/tra_production_predeployment.csv` was compared with the approved `tra_production_full_inventory.csv.csv` on 10 November 2026.

- Both files exist and use the required `section,object_schema,object_name,details` structure.
- Both contain 463 rows and 16 non-empty required inventory sections plus `export_manifest`.
- Both files have the same SHA-256: `458D41DA8FE6C7D42A56DBE69C4F681469568936C318EF548E0A185346046E17`.
- There are no duplicate `(section, object_schema, object_name)` keys.
- All 11 data-quality issue counts remain zero.
- Exact byte equality proves there are no semantic or non-semantic differences in the supplied exports.

| Section | Rows | Drift |
|---|---:|---|
| check_constraint | 2 | None |
| column | 65 | None |
| column_grant | 12 | None |
| data_quality | 11 | None |
| enum | 9 | None |
| foreign_key_constraint | 9 | None |
| function | 8 | None |
| function_grant | 33 | None |
| index | 11 | None |
| object_catalog | 53 | None |
| primary_key_constraint | 7 | None |
| rls_policy | 20 | None |
| rls_table | 7 | None |
| table_grant | 191 | None |
| trigger | 5 | None |
| unique_constraint | 4 | None |
| export_manifest | 16 | None |

**Drift decision: PASS.** The rehearsed artist authentication migration remains compatible with the supplied predeployment production schema.

## Test environment

- Supabase CLI 3.0.0, local project ID `tra-project`.
- Supabase PostgreSQL 17.11 container, GoTrue 2.197.0, PostgREST 16.5, Kong, and Mailpit.
- Localhost-only API/database; no hosted Supabase project was linked.
- Production-like baseline reconstructed from the inventory: seven scoped tables, enums, defaults, seven PKs, four unique constraints, nine FKs, 11 indexes, five pre-existing triggers, five required functions, 20 RLS policies, table/column/function grants, and synthetic records.
- Five fixed synthetic database users plus one unique GoTrue signup were used. No production personal information was copied.

## Results

| Check | Status | Evidence | Risk |
|---|---|---|---|
| Inventory/static compatibility | PASS | Approved and predeployment exports are byte-identical: 463 rows, all 16 sections plus manifest, matching prerequisites and target names. | Low |
| Initial transactional failure behavior | PASS | First rehearsal exposed `name[] = text[]` in equivalent-index detection. PostgreSQL aborted and rolled back all migration changes; zero partial columns/RPCs remained. | Low |
| Corrected migration execution | PASS | After casting `pg_attribute.attname` to `text`, the transaction reached `COMMIT` on a clean reconstructed baseline. | Low |
| Existing data preservation | PASS | Pre-existing onboarding note and legal acceptance snapshot remained byte-for-byte equal after forward migration and rollback. | Low |
| Existing RLS preservation | PASS | All 20 policy names and definitions matched the pre-migration hash after forward migration and rollback. | Low |
| Existing grant preservation | PASS | Table-grant and explicit `pg_attribute.attacl` hashes matched before/after migration and rollback; registration EXECUTE remained authenticated/service-only. | Low |
| Verification SQL | PASS | All 13 issue counts were zero: nine primary checks plus four artist identity/onboarding checks. | Low |
| Functions and triggers | PASS | Five target functions had expected SECURITY DEFINER/search paths and grants; immutable evidence trigger covered INSERT/UPDATE/DELETE without name conflicts. | Low |
| Artist registration | PASS | Verified registration created/reused one artist profile, one literal artist role, and one onboarding row. Repeated SQL and HTTP registrations returned the same profile. | Low |
| Email verification | PASS | Actual local GoTrue signup received no session; password login was rejected before confirmation; Mailpit confirmation token succeeded; verified login then returned a session. | Low |
| Profile/onboarding draft | PASS | Guarded save RPC updated only permitted profile fields and the caller's editable draft. | Low |
| Mandatory legal acceptance | PASS | Submission failed before acceptance, then succeeded after current mandatory version acceptance. Server populated body snapshot, content hash, timestamp, and statement. | Low |
| Acceptance immutability | PASS | Artist had no update path; an authenticated admin with row access was rejected by `LEGAL_ACCEPTANCE_IMMUTABLE`. | Low |
| Artist isolation | PASS | Artist could read exactly one owned onboarding record and could not read the other artist's row. | Low |
| Approval permissions | PASS | Artist approval UPDATE affected zero rows; verified admin permission updated the record successfully. | Low |
| Privilege escalation | PASS | Artist attempt to insert an admin role failed; registration function accepts no role parameter and created only `artist`. | Low |
| Anonymous restrictions | PASS | Anonymous caller could not execute registration or read artist-only legal content. | Low |
| Rollback execution | PASS | Transaction committed; migration-specific trigger/functions/index were removed and the captured original registration function was restored. | Low |
| Rollback preservation | PASS | Existing rows, all 20 policies, table/column grants, pre-existing helper functions, and registration grants remained intact. | Low |
| Retained evidence columns | PASS | `acceptance_statement` and `accepted_content_sha256` intentionally remained after rollback to avoid destroying post-migration evidence. | Medium |
| TypeScript | PASS | `npm.cmd run typecheck` (`tsc --noEmit`) exited 0. | Low |
| Automated tests | PASS | `npm.cmd test`: 15/15 passed, including migration safety and catalogue regression checks. | Low |
| Production build | PASS | Next.js 16.4.5 build compiled, typechecked, and generated 21/21 static pages; exit 0. | Low |

## Migration correction discovered by rehearsal

The equivalent-index checks aggregated `pg_attribute.attname` as PostgreSQL `name[]` and compared it to a `text[]` literal. PostgreSQL 17 correctly rejected the missing `name[] = text[]` operator. All three expressions now use `array_agg(a.attname::text ...)`. A static regression assertion requires all three casts.

The earlier zero-based `pg_index.indkey[0]` correction and all 20 policy preflight checks remain in place. No data-changing behavior or production policy definition was changed.

## Reproducible rehearsal assets

- `supabase/tests/artist_auth_production_baseline.sql` — synthetic production-compatible baseline and preservation hashes.
- `supabase/tests/artist_auth_security_tests.sql` — database authentication, authorization, legal, RLS, and grant tests.
- `supabase/tests/artist_auth_http_rehearsal.ps1` — local GoTrue/Mailpit/PostgREST email-verification and registration test.
- `supabase/tests/artist_auth_rollback_verify.sql` — rollback object/data/policy/grant verification.
- `supabase/tests/artist_auth_rehearsal_cleanup.sql` — fixed-scope disposable fixture cleanup only.

## Outstanding operational risks and required production steps

1. Archive the predeployment inventory and its recorded SHA-256 with the approved release evidence; repeat the export if the maintenance window is delayed or any database change occurs.
2. Confirm the hosted production PostgreSQL major version and take a restorable backup.
3. Baseline production migration history before using any CLI push workflow. `202611050001_foundation.sql` is fresh-project-only and must not be replayed on production.
4. Apply only the reviewed artist-auth migration through an approved maintenance procedure, then run `verify_artist_auth_migration.sql`; every issue count must be zero.
5. Run a production smoke test with dedicated non-personal test artist/admin accounts, then remove or retain those accounts according to the approved test-data policy.
6. The intentionally retained evidence columns require a separate, explicit data-retention decision if rollback is ever used.
7. Review broad pre-existing table privileges and PUBLIC EXECUTE on trigger helpers in a separate least-privilege migration; they were preserved, not silently changed here.

No production SQL was executed. Nothing was merged into `main` or deployed to Netlify.
