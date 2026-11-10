# Deployment runbook

## Application-only release

1. Open a pull request to `main`; review the diff and generated preview.
2. Require `required-checks` to pass and obtain the configured approval.
3. Run the preview smoke workflow against the Netlify preview URL if no deployment event was emitted.
4. Merge only after approval. The existing Netlify project deploys `main` automatically.
5. Confirm the deployment-verification workflow and production availability workflow pass.
6. If smoke checks fail, stop traffic promotion/rollback to the last known-good Netlify deploy from the existing site's Deploys page, then investigate. No database rollback is implied for an application-only release.

## Database release

Production migration execution is never automated. It additionally requires a verified backup, a successful rehearsal for the exact SQL checksum, no production inventory drift, and explicit production approval from the database owner/release approver.

1. Freeze the approved migration, verification, rollback, and inventory files; record SHA-256 values in the release ticket.
2. Create and restore-test a production backup according to `docs/PRODUCTION_ROLLOUT_CHECKLIST.md`. Record location, timestamp, exclusions, PostgreSQL version, and restoration evidence without credentials.
3. Export the current production inventory with `supabase/production_schema_complete_export.sql`; compare it to the approved inventory. Any unexplained difference blocks execution.
4. Confirm the production PostgreSQL major version matches `supabase/config.toml` and the rehearsal.
5. Reconcile the already-present foundation migration in migration history without replaying it: after read-only confirmation of the existing schema and explicit approval, use the appropriate linked-project command equivalent to `supabase migration repair 202611050001 --status applied`. Preview/list history first. Never run `db push` merely to repair history.
6. Obtain explicit production approval for the named database/project, exact checksum, maintenance window, operator, observer, and rollback/restore decision authority.
7. In the approved production SQL session, run `supabase/production_rollout_preflight.sql` read-only and save the result. Stop on any issue.
8. Apply only `supabase/migrations/202611090001_artist_auth.sql`. It is transactional; do not edit it during the window.
9. Immediately run `supabase/verify_artist_auth_migration.sql`. All critical issue counts must be zero. Run the dedicated artist/admin smoke cases from the production rollout checklist using approved synthetic accounts.
10. If verification fails, stop the application release. Decide between the reviewed rollback and full restore based on whether real acceptance evidence has been created. The rollback intentionally retains evidence columns.
11. Record migration history only after successful verification. Preserve logs with secrets and personal data redacted.

## Recovery rules

- Before user activity: the reviewed rollback can remove migration-specific functions/trigger/index and restore the prior registration function.
- After legal acceptances exist: do not remove or rewrite evidence. Rollback retains the evidence columns; legal/audit ownership decides the recovery path.
- Suspected corruption or partial external failure: isolate writes, preserve logs, and restore into a disposable database first. A production restore requires separate approval.
- Never run the foundation migration against the existing production schema.

## Smoke expectations

Artist: registration email requires verification; login works after verification; only `artist` is assigned; draft onboarding belongs to the user; mandatory legal acceptance gates submission; another artist's data is not visible.

Administrator: anonymous and artist requests cannot access `/admin` or approve onboarding; a verified administrator with the database-backed admin role can review; attempts to self-assign `admin` fail; acceptance evidence cannot be updated or deleted.
