# Production schema compatibility review

Assessment date: 10 November 2026.

## Evidence reviewed

The complete inventory is stored as `docs/database-inventory/tra_production_full_inventory.csv.csv` (the export has an extra filename extension). It contains 463 rows and all 16 declared sections: columns, PKs, unique/FK/check constraints, indexes, RLS flags and policies, triggers, functions, function grants, enums, table/column grants, object catalogue, data quality, and manifest.

The inventory confirms the seven scoped tables, 65 columns, seven PKs, four unique constraints, nine validated FKs, 11 indexes, two checks, seven RLS-enabled tables, 20 policies, five relevant triggers, eight functions, 33 function grants, 191 table grants, 12 explicit column grants, and 11 zero-valued duplicate/orphan checks.

## Compatibility conclusions

- `profiles.id` is the Auth identity; `artist_profiles.id` is the artist-domain identity. The migration preserves this distinction.
- `artist_profiles.user_id` is unique, non-null, and references `auth.users.id ON DELETE CASCADE`.
- `artist_onboarding_requests.artist_id` references `artist_profiles.id ON DELETE CASCADE`.
- Legal acceptance user/version FKs and legal version/document FK use RESTRICT, preserving evidence history.
- Existing PK/unique indexes satisfy role, artist-profile, and legal-acceptance conflict targets. Only onboarding artist uniqueness is added conditionally.
- `tra_role` contains `artist` and `admin`; `artist_status` contains all workflow values used by the migration.
- Existing Auth and updated-at triggers do not conflict with the migration trigger.
- Existing registration RPC is deliberately extended with the same signature and return type; rollback restores its captured body.
- Existing 20 RLS policies and all table/column grants are preserved. Preflight now requires every policy by table and name.
- Registration EXECUTE is available to authenticated/service roles and not anon/PUBLIC. New callable RPCs follow the same restriction.
- All exported duplicate/orphan counts are zero, including artist-profile/Auth and onboarding/profile integrity.
- New function, trigger, and conditional-index names do not conflict with inventory objects.

## Rehearsal result

The migration, verification SQL, database/RLS security suite, actual local GoTrue email-confirmation flow, and rollback were executed on a disposable Supabase PostgreSQL 17 stack reconstructed from this evidence. The final forward migration committed; all verification issue counts were zero; security and rollback suites passed.

Rehearsal found and corrected one PostgreSQL type error: equivalent-index detection compared `name[]` with `text[]`. All three aggregates now cast `pg_attribute.attname::text`. The failed attempt rolled back fully before the corrected migration was rerun.

See `docs/MIGRATION_READINESS.md` for exact results, residual operational risks, and the GO decision.

## Production safeguards

- Never replay the fresh-project `202611050001_foundation.sql` on production.
- Re-export inventory immediately before application and stop on drift.
- Baseline hosted migration history before any CLI push workflow.
- Take a restorable backup, apply only the reviewed migration, and require every verification count to be zero.
- Rollback intentionally retains the two acceptance-evidence columns because they can contain historical evidence.

No production SQL was executed during this review or rehearsal.
