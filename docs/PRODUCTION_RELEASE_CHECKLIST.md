# Production release checklist

## Approval and evidence

- [ ] Release pull request is approved and targets `main`.
- [ ] `required-checks` is green for the exact commit.
- [ ] Netlify preview uses `tra-development`, not production Supabase.
- [ ] Preview smoke tests pass.
- [ ] Existing Netlify project `therealart.in` is selected; no duplicate site was created.
- [ ] Production environment variables were reviewed without displaying values.
- [ ] Release owner and rollback owner are named.

## Additional database-change gates

- [ ] Exact migration/verification/rollback SHA-256 values are recorded.
- [ ] Read-only predeployment inventory has no unexplained drift.
- [ ] Disposable PostgreSQL forward, verification, RLS, Auth, and rollback tests pass for the exact commit.
- [ ] Backup includes schema and data plus roles where supported; exclusions are documented.
- [ ] Backup restore has passed in a disposable database.
- [ ] Foundation migration is marked applied in history without replaying it.
- [ ] Production PostgreSQL major version is compatible.
- [ ] Production preflight result is clean.
- [ ] Explicit production migration approval is recorded.
- [ ] Maintenance and recovery windows are open.

## Post-release application checks

- [ ] `https://therealart.in` returns 200.
- [ ] `/artworks`, `/join-as-artist`, and `/login` return 200.
- [ ] Anonymous `/admin` redirects to login/access denied.
- [ ] Critical API rejects an untrusted origin without exposing details.
- [ ] Netlify deployment status and production availability workflows pass.
- [ ] Logs contain no tokens, credentials, acceptance bodies, or personal information.

## Post-migration checks

- [ ] Every critical count from `verify_artist_auth_migration.sql` is zero.
- [ ] Pre-existing RLS policy names/definitions and grants remain present.
- [ ] Registration creates only the artist role and one owned draft.
- [ ] Unverified email cannot sign in; verified email can.
- [ ] Repeated registration is idempotent.
- [ ] Mandatory current legal versions are required before submission.
- [ ] Legal acceptance timestamp, snapshot, statement, and hash are immutable.
- [ ] Cross-artist reads/updates fail.
- [ ] Artist approval and privilege escalation fail.
- [ ] Verified administrator approval succeeds.
- [ ] Migration history and release evidence are archived.

## Stop conditions

Any failed required check, unexplained drift, missing/untested backup, PostgreSQL version mismatch, non-zero verification count, RLS/grant change, synthetic-account cleanup failure, or missing explicit approval is a release blocker. Do not merge, deploy, or migrate until resolved.
