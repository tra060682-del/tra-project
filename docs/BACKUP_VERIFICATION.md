# Production database backup verification

Verification date: 10 November 2026 (Pacific/Auckland)

## Scope and safety

- Source: existing production Supabase project `aewoiynwpyqawiluwlkj` (`tra060682-del's Project`), PostgreSQL `17.11.0.018`.
- Destination: `C:\tra\backups\tra-production-20261110-134512`, outside the Git repository.
- Method: authenticated Supabase CLI 3.1.0 `db dump` operations. No migration, DDL, DML, Auth-setting change, or production deployment was issued.
- Workspace link: non-production `tra-development` project `ocstvctvmychromkcurw` only.

## Backup components

| File | Purpose | Bytes | SHA-256 |
|---|---|---:|---|
| `schema.sql` | application schemas, types, functions, tables, constraints, indexes, policies, triggers and grants | 73,081 | `7DB37163E4660EE6F6A10BEDA8611FF76F531CDDF72626A9089ECE68E0673E3F` |
| `data.sql` | PostgreSQL data using `COPY`, including database-resident Auth and Storage metadata | 22,433 | `C8570E0EDDCD201CC8664F61C91120C1C90515C5C0EE83E8E8690239516AD0E4` |
| `roles.sql` | supported role settings for `anon`, `authenticated`, and `authenticator` | 297 | `25873CEC56A2CC6514E204F420231777F85C03DA818CAA7090CDCDFA89776ECD` |

All three files were non-empty and were re-read successfully for SHA-256 calculation.

## Restore rehearsal

The final rehearsal used a clean local Supabase PostgreSQL 17.11 stack so the managed Auth and Storage schemas were initialized before restore. The platform restore administrator replayed roles, schema, and data with `ON_ERROR_STOP=1`; all three completed successfully.

Restored aggregate evidence:

| Schema | Tables | Rows |
|---|---:|---:|
| `auth` | 27 | 82 |
| `public` | 28 | 22 |
| `storage` | 12 | 80 |

Structural checks: 119 public constraints, 52 public indexes, 60 public RLS policies, zero invalid indexes, and zero `artist_profiles.user_id` orphans against `auth.users`.

Two failed attempts were useful compatibility checks:

1. A plain PostgreSQL image lacked Supabase's managed `extensions` schema.
2. The database image alone had an older/unmigrated managed Auth schema and later lacked Storage-owner privileges for metadata restore.

These failures did not affect production. They show that restoration must target a compatible, initialized Supabase stack and use the platform restore administrator—not an arbitrary empty PostgreSQL database or ordinary migration role.

## Migration compatibility on the restored backup

The exact `202611090001_artist_auth.sql` migration was applied transactionally to the restored current backup. `verify_artist_auth_migration.sql` completed with all 13 critical issue counts at zero (nine main checks plus four identity/onboarding checks). The rollback script then completed; migration RPCs and immutable trigger were removed, the 60 existing policies remained, indexes remained valid, artist/Auth orphans remained zero, and the two legal-evidence columns were intentionally retained.

## Auth and Storage limitations

- Database-resident Auth rows were included and restored. Supabase dashboard Auth configuration, SMTP/provider secrets, OAuth client secrets, JWT signing material, CAPTCHA settings, redirect URL configuration, and external identity-provider state are not a complete part of this SQL backup. Export/document those settings separately through approved secure procedures.
- Storage database metadata was included and restored. Object bytes in Supabase Storage are stored outside PostgreSQL and are **not** contained in `data.sql`; bucket objects require a separate Storage object export/copy and restoration test. Signed URLs and cached derivatives are not backup artifacts.
- The role dump contains supported role settings, not a portable backup of every Supabase-managed role secret or platform credential.
- Point-in-time recovery and Supabase platform backups remain separate service capabilities and should complement, not replace, this export.

## Development project status

CLI authentication and access are confirmed. The workspace is linked to `ocstvctvmychromkcurw`; its remote migration history is empty. No hosted development migration was applied.

The repository's `202611050001_foundation.sql` does not represent the current production baseline (it contains a materially different auction-era schema and lacks the legal/onboarding prerequisites). Replaying it into `tra-development` would create an invalid test baseline. Development initialization therefore requires a reviewed, schema-only production-compatible baseline with synthetic seeds, followed by marking the historical foundation version applied without executing the incompatible SQL and then applying the artist-auth migration.

## Readiness decision

**Backup: PASS and restorable with documented Supabase prerequisites.**

**Production migration execution: NO-GO pending explicit production approval and the normal change-window preflight.** Technical compatibility against the current restored backup passed, but this report does not authorize production execution. The separate development project also remains uninitialized until the safe baseline step above is completed.
