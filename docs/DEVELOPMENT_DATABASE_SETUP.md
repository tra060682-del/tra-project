# Supabase development database setup and recovery

## Current development environment

| Item | Value |
|---|---|
| Project | `tra-development` |
| Project ref | `ocstvctvmychromkcurw` |
| PostgreSQL | 17.11 |
| Production data copied | No |
| Production Auth identities copied | No |
| Production Storage objects copied | No |

The project was empty before initialization: no public tables, zero Auth rows, zero Storage rows, and no migration history. A schema/data/roles backup was saved outside Git at `C:\tra\backups\tra-development-prebaseline-20261110-141545` before any change.

## Applied history

1. `202611050001` was marked applied with `migration repair`; its incompatible auction-era SQL was never executed.
2. `202611080001_production_compatible_baseline.sql` recreated the reviewed production structure without table data.
3. `202611090001_artist_auth.sql` added the reviewed artist authentication/onboarding changes transactionally.

Never run `202611050001_foundation.sql` against this project. Before every push, use a dry run and require the output to name only reviewed pending migrations:

```powershell
npx.cmd --yes supabase@latest db push --remote=ocstvctvmychromkcurw --include-all --dry-run
```

## Development-only data and objects

`supabase/seed.development.sql` refuses to run if Auth users, buyers, artist profiles, legal acceptances, or sales exist. It creates only:

- one clearly synthetic mandatory artist agreement and published version;
- a development guard marker;
- synthetic support and commission configuration;
- two synthetic taxonomy entries.

`supabase/development_cleanup.sql` creates a development-only cleanup RPC. It requires the development marker and a target `ci.*@example.test` Auth email, locks legal acceptance records, temporarily disables the immutable-evidence trigger within that transaction, removes only the synthetic user's application records, and is executable only by `service_role`. It must never be added to a production migration or applied to production.

## Verification

Run the consolidated read-only verification:

```powershell
npx.cmd --yes supabase@latest db query `
  --remote=ocstvctvmychromkcurw --read-only `
  --file supabase/tests/artist_auth_verification_counts.sql
```

Exactly 13 rows must be returned and every `issue_count` must be zero. `development_state_verification.sql` must show zero synthetic Auth users, artist profiles, and legal acceptances after CI; the cleanup RPC must be denied to `anon` and `authenticated` and allowed to `service_role`.

The hosted integration script uses generated signup tokens rather than an external mailbox. It verifies that unconfirmed login fails, confirms the signup token, tests verified login/logout, idempotent artist registration, artist-only role assignment, onboarding drafts, the mandatory legal gate, immutable evidence, cross-artist isolation, anonymous denial, self-approval prevention, privilege-escalation prevention, administrator approval, and cleanup.

### Completed validation — 10 November 2026

| Check | Result |
|---|---|
| Remote migration history | `202611050001`, `202611080001`, and `202611090001` aligned |
| Consolidated migration verification | 13/13 issue counts zero |
| Hosted Auth/RLS integration | PASS, including automatic cleanup |
| Post-test synthetic Auth users | 0 |
| Post-test artist profiles / legal acceptances | 0 / 0 |
| Cleanup grants | `anon=false`, `authenticated=false`, `service_role=true` |
| Supabase database lint | PASS, no schema errors |
| TypeScript | PASS |
| Unit/integration tests | 18/18 PASS |
| Playwright | 6/6 PASS |
| Next.js production build | PASS, 21/21 pages generated |

## Environment variables

Local `.env.local` and Netlify Deploy Preview contexts use:

```text
NEXT_PUBLIC_SUPABASE_URL=https://ocstvctvmychromkcurw.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<development publishable key>
NEXT_PUBLIC_SITE_URL=<exact local or preview origin>
```

GitHub's protected `development` environment requires the secrets documented in `ENVIRONMENT_CONFIGURATION.md`. The service-role/secret key is CI-only and must never use a `NEXT_PUBLIC_` name. Configure development Auth redirect URLs for local callbacks and the exact existing Netlify preview hostname; do not reuse production Auth credentials or production redirect settings.

## Routine migration procedure

1. Confirm `supabase/.temp/project-ref` is `ocstvctvmychromkcurw` and run `projects list`.
2. Create a fresh development backup outside Git.
3. Run `db push --dry-run`; stop if the incompatible foundation or any unreviewed file is listed.
4. Rehearse locally through `npm run test:database`.
5. Apply reviewed migrations only to the explicit development ref.
6. Run the 13 checks, hosted integration suite, cleanup verification, database lint, TypeScript, tests, E2E, and build.
7. Record migration versions and checksums.

Production migration execution remains a separate manual, approved procedure. Never infer production approval from a successful development run.

## Recovery

For a failed change, stop integration jobs and take a new diagnostic dump before altering anything. Prefer the reviewed migration rollback when it preserves evidence. If a full development rebuild is approved:

1. retain the latest development backup outside Git;
2. reset only `ocstvctvmychromkcurw` after verifying the exact ref;
3. mark `202611050001` applied without executing it;
4. apply the production-compatible baseline and subsequent reviewed migrations;
5. apply the guarded development seed and cleanup RPC;
6. rerun all 13 checks and hosted security tests.

Do not restore production data into development. Do not restore SQL directly into managed Auth or Storage schemas unless using a compatible initialized Supabase stack and the platform restoration procedure.
