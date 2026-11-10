# Artist authentication controlled production rollout

Prepared: 10 November 2026
Branch: `feature/tra-artist-onboarding`
Production origin: `https://therealart.in`

## Current release status

**HOLD pending production evidence and approvals.** The migration itself has a GO result from PostgreSQL 17.11 rehearsal, but production execution is not yet authorized.

Current blockers:

1. The production inventory has no `server_version` evidence. Run the read-only preflight and approve the returned version.
2. The inventory snapshot must be re-exported immediately before the maintenance window and compared with the reviewed snapshot.
3. The working tree contains reviewed but uncommitted modifications and untracked rollout artifacts. Create and review a feature-branch commit before any production command.
4. Confirm a restorable Dashboard backup/PITR point and record its UTC timestamp before migration-history repair.
5. Obtain database owner, security reviewer, release owner, and business owner approvals.

Preparation-time Git check: branch is `feature/tra-artist-onboarding`; the worktree has 10 modified tracked paths and 24 untracked paths. This is not a deployable release state.

## Frozen reviewed artifacts

| Artifact | SHA-256 |
|---|---|
| Production inventory (`.csv.csv`) | `458D41DA8FE6C7D42A56DBE69C4F681469568936C318EF548E0A185346046E17` |
| `202611090001_artist_auth.sql` | `48441BAD0D4CD05C16F7CAA8E0757C02F9BC10B09C6E2A41F744863A0347AB20` |
| `verify_artist_auth_migration.sql` | `A72BDD36F9A469FE19A7140B94170CB8403EE4E32AB544039693D48BD233BF5F` |
| Rollback SQL | `A7F71D34A362663D6AE6F434E00A2241942CF1F79EE3ED1063C93549DA821C64` |

Recalculate and compare these hashes from the approved commit. Any difference requires re-review and rehearsal.

## Inventory-to-rehearsal comparison

| Area | Production inventory | Rehearsed baseline | Result |
|---|---:|---:|---|
| Scoped tables | 7 | 7 | Match |
| Columns | 65 | 65 | Match |
| Primary keys | 7 | 7 | Match |
| Unique constraints | 4 | 4 | Match |
| Foreign keys | 9 | 9 | Match, including delete actions |
| Check constraints | 2 | 2 | Match |
| Indexes | 11 | 11 | Match |
| Enum labels | 9 | 9 | Match |
| Existing triggers | 5 | 5 | Match |
| RLS-enabled tables | 7 | 7 | Match |
| Existing RLS policies | 20 | 20 | Names/definitions reproduced |
| Duplicate/orphan checks | 11 zero counts | Same synthetic invariants | Compatible |
| Relevant functions | 5 migration dependencies | Same 5 | Match |
| Other inventoried functions | 3 unrelated helpers | Not recreated | No migration dependency |
| Grants | 191 table, 12 column, 33 function rows | Required role/ACL behavior reproduced and hash-preserved | Compatible, not a byte-for-byte full clone |

No incompatibility is known in the reviewed snapshot. Drift after its export cannot be ruled out without the just-in-time re-export.

## PostgreSQL version gate

Run `supabase/production_rollout_preflight.sql` read-only in the SQL Editor. Record `server_version` and `server_version_num`.

- Major version 17: compatible with the completed PostgreSQL 17.11 rehearsal.
- Major version 15: migration syntax is statically compatible, but run the same disposable rehearsal on the exact production major/minor before approval.
- Any other major version: **STOP / NO-GO** pending a matching rehearsal.

Do not upgrade PostgreSQL as part of this rollout.

## Backup and restoration procedure

### Mandatory primary backup

1. In Supabase Dashboard, open **Database → Backups**.
2. If PITR is enabled, record the latest restorable UTC point immediately before the change. If daily backups are used, confirm a completed backup exists and record its identifier/time and retention expiry.
3. Confirm the restore action is available to the designated database owner. Record the owner and a second approver.
4. Record the current application release/commit and the seven preflight row counts.
5. Do not continue if no restorable point is visible.

### Supplemental logical backup

Store dumps in an encrypted location outside the repository. Do not paste credentials into commands or logs.

```powershell
npx.cmd --yes supabase@latest db dump --remote -f <secure-backup-dir>/pre-artist-auth-schema.sql
npx.cmd --yes supabase@latest db dump --remote --data-only --use-copy -f <secure-backup-dir>/pre-artist-auth-data.sql
npx.cmd --yes supabase@latest db dump --remote --role-only -f <secure-backup-dir>/pre-artist-auth-roles.sql
Get-FileHash -Algorithm SHA256 <secure-backup-dir>/pre-artist-auth-*.sql
```

The CLI dump excludes Supabase-managed schemas such as Auth by default, so it supplements rather than replaces Dashboard backup/PITR.

### Restoration decision

- For migration-only behavior rollback with an otherwise healthy database, use the reviewed rollback SQL transactionally, then run rollback verification. Evidence columns are deliberately retained.
- For unexpected data/schema corruption, stop writes and restore the recorded pre-change Dashboard backup or PITR point. Restoration replaces the current database state and causes downtime.
- Before a full restore, identify non-Realtime replication slots/subscriptions; Supabase requires these to be removed and recreated. After restore, reset any custom-role passwords omitted from daily backups and verify Auth, RLS, API, and application health.
- Supabase database restore does not restore deleted Storage objects. This migration does not modify Storage, but the limitation must be acknowledged.

## Foundation migration-history reconciliation

`202611050001_foundation.sql` is for a fresh project and is not production-compatible. It must never be replayed on production.

After linking the CLI to the confirmed production project, first run only:

```powershell
npx.cmd --yes supabase@latest migration list --remote
```

Expected decision:

- If `202611050001` is already recorded as applied, do not repair it.
- If absent, and production schema has passed the complete inventory comparison, obtain two-person approval and mark history only:

```powershell
npx.cmd --yes supabase@latest migration repair 202611050001 --status applied --remote
npx.cmd --yes supabase@latest migration list --remote
```

`migration repair` updates `supabase_migrations.schema_migrations`; it does not execute foundation SQL. Stop if the list contains unexpected versions or if `202611090001` is already present.

## Exact migration execution sequence

All commands below require the recorded maintenance-window approval. Do not use `--include-all`, `--include-seed`, or `--include-roles`.

1. Confirm the approved commit, clean worktree, hashes, project reference, production domain, backup/PITR point, and named rollback operator.
2. Run the complete inventory export and `production_rollout_preflight.sql`; archive outputs. Every issue count must be zero and no unexpected active/long transaction may remain.
3. Reconcile foundation history as above.
4. Dry-run:

   ```powershell
   npx.cmd --yes supabase@latest db push --dry-run --remote
   ```

   It must list exactly `202611090001_artist_auth.sql`. Otherwise stop.

5. Put artist registration/onboarding into the approved maintenance state or temporarily stop application writes.
6. Apply:

   ```powershell
   npx.cmd --yes supabase@latest db push --remote
   ```

7. Immediately run `supabase/verify_artist_auth_migration.sql` in SQL Editor. Every issue count must be zero; authenticated RPC grants must be true, anon grants false, and 20 existing policies must remain.
8. Compare the seven post-migration row counts with the preflight snapshot. Expected increases are only from subsequently approved smoke-test accounts/actions.
9. Run smoke tests below. Monitor Database/Auth/API logs.
10. Release maintenance state only after database, security, release, and business owners sign off.

If migration execution fails, its transaction should roll back. Capture the complete error, rerun read-only preflight/verification, and do not retry without review.

## Dedicated production smoke tests

Use pre-approved synthetic QA identities; never use personal accounts or hardcoded credentials. Because legal acceptances are immutable and use restrictive FKs, an artist that accepts legal terms becomes retained audit evidence. Approve that retention before testing.

### Artist account

1. Register at `/join-as-artist` with the dedicated QA artist.
2. Confirm no session is granted before email verification.
3. Follow the production verification email and confirm redirect to `/auth/callback`, then `/artist`.
4. Confirm exactly one `profiles` row, one `artist_profiles` row, one literal `artist` role, and one draft onboarding row.
5. Repeat registration/callback safely; confirm no duplicate role/profile/onboarding.
6. Save an onboarding draft and confirm another artist cannot read or change it.
7. Confirm submission is blocked before all mandatory current legal versions are accepted.
8. Accept the approved QA legal version; verify timestamp, snapshot, hash, statement, user agent/IP handling, and immutability.
9. Submit onboarding; confirm status is `submitted` and self-approval is impossible.
10. Attempt admin-role insertion and confirm RLS rejection. Confirm `/admin` denies access.
11. Test logout, login, password reset callback, expired/invalid callback, and safe redirect handling.

### Administrator account

1. Use a separately verified, pre-approved QA administrator whose UUID has the trusted `admin` role. Never assign admin from metadata, email matching, or public parameters.
2. Confirm `/admin` access and visibility of the QA artist/onboarding.
3. Approve or request changes on only the QA record and verify audit fields (`reviewed_by`, `reviewed_at`, remarks/status).
4. Confirm admin cannot UPDATE or DELETE legal acceptance evidence because the immutable trigger rejects it.
5. Confirm no unrelated artist/profile/onboarding rows changed.

### Anonymous checks

1. Confirm registration RPC execution is denied without an authenticated token.
2. Confirm artist-only legal documents, profiles, onboarding, roles, and acceptances are not exposed.
3. Confirm public gallery behavior is unchanged.

## Supabase Auth URL configuration

Review only until the separate Auth-settings approval is granted:

- Site URL: `https://therealart.in`
- Required production redirect URL: `https://therealart.in/auth/callback`
- Email confirmation: enabled
- Password recovery uses the same callback with `next=/reset-password`.
- Do not use a wildcard production redirect. Add localhost or Netlify preview patterns only to non-production/preview configurations or through a separately approved change.

The confirmation and recovery templates must preserve the application-provided `redirectTo` value.

## Netlify environment variables

Required in the **Production** context:

| Variable | Value/source | Exposure |
|---|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Production project API URL | Public by design |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Production publishable/anon key | Public by design; RLS mandatory |
| `NEXT_PUBLIC_SITE_URL` | `https://therealart.in` (no trailing slash) | Public |

Cloudinary variables are not currently required for Phase 1. When uploads are enabled, `CLOUDINARY_API_SECRET` must remain server-only. Never add a Supabase service-role key to a `NEXT_PUBLIC_*` variable or expose it to the browser.

Changing Netlify variables or triggering a deploy requires separate approval and is outside this database rollout.

## Final approvals

- [ ] Feature-branch commit reviewed; worktree clean; hashes match.
- [ ] Just-in-time production inventory shows no drift.
- [ ] Production PostgreSQL version recorded and compatible.
- [ ] Backup/PITR point and restoration owner confirmed.
- [ ] Foundation migration-history repair approved, if required.
- [ ] Database owner approves migration and rollback.
- [ ] Security reviewer approves RLS/grants/Auth configuration.
- [ ] Release owner approves maintenance window and commands.
- [ ] Business owner approves synthetic production smoke-test records and legal-evidence retention.
- [ ] Netlify/Auth configuration changes, if any, have separate approval.

No production SQL, Auth setting, database record, migration-history repair, merge, or deployment was performed while preparing this checklist.
