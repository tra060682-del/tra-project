# CI/CD setup

The repository now separates validation, non-production integration, deployment verification, and production authorization. No workflow applies a production migration or invokes a production Netlify deploy.

## Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `Required checks` | pull requests; pushes to `main` and the feature branch | TypeScript, unit/integration tests, build, high-severity dependency audit, Chromium E2E, inventory drift check, disposable Supabase forward/RLS/rollback rehearsal |
| `Development Supabase integration` | feature-branch pushes, weekly, and manual | Runs the full synthetic Auth/legal/onboarding/admin/RLS lifecycle only in `tra-development`, cleans up, then runs all 13 read-only checks |
| `Deployment verification` | successful GitHub deployment status or manual URL | Runs route smoke checks and read-only Playwright registration/login/authorization checks on approved Netlify/production hostnames |
| `Production availability` | every 30 minutes and manual | Checks public pages, anonymous admin restriction, and critical API origin protection |

The disposable database job starts the local Supabase PostgreSQL 17 stack, reconstructs the approved production-like baseline, applies `202611090001_artist_auth.sql`, runs verification and security assertions, exercises local Auth and email confirmation, rolls back, and verifies preservation. Its report is retained as a workflow artifact for 30 days.

## Required repository configuration

1. Create a GitHub environment named `development`; add the development-only secrets listed in [ENVIRONMENT_CONFIGURATION.md](ENVIRONMENT_CONFIGURATION.md). Use environment secrets, not repository secrets. Restrict deployment branches to `feature/tra-artist-onboarding` (and `main` only when intentionally enabled), require an authorised reviewer, prevent self-review and do not allow administrator bypass. Do not place production database secrets there.
2. Protect `main`: require a pull request, at least one approval, dismissal of stale approvals, resolution of conversations, up-to-date branches, and the `required-checks` status. Restrict bypass and direct pushes.
3. In repository Actions settings, allow only required actions or GitHub-authored actions and pin this policy as appropriate for the organisation.
4. Enable Dependabot alerts and secret scanning. Dependabot is configured for grouped npm and Actions update pull requests.
5. Configure notifications for failed scheduled workflows to the operating team.

Fork and ordinary pull-request workflows receive no Supabase secrets. The required PR suite needs none. The privileged development workflow has no `pull_request` trigger and is separately protected by the `development` environment. Never change it to `pull_request_target` or check out untrusted pull-request code while environment secrets are available.

## Netlify checks

Connect the existing Netlify project `therealart.in` to this repository; do not create another site. Set `main` as the production branch, enable Deploy Previews for pull requests, and require successful GitHub checks before merge. `netlify.toml` runs `npm run build:netlify`. The build guard rejects preview/branch deploys unless the Supabase hostname exactly matches `ocstvctvmychromkcurw.supabase.co`; it also rejects secret/service-role keys and assigns the preview origin from `DEPLOY_PRIME_URL`.

Netlify's GitHub deployment status triggers the deployment-verification workflow when the integration publishes one. If the account integration does not emit GitHub deployment events, add `npm run test:smoke` as a Netlify post-processing/build hook or run the workflow manually with the deployed HTTPS URL.

## Failure handling

- Application or E2E failure: no merge; use the uploaded Playwright trace/report.
- Migration failure: no database release; inspect `migration-readiness` and rerun locally.
- Dependency audit failure: upgrade or document a time-bounded exception through review; do not lower the threshold silently.
- Development integration cleanup failure: run the guarded `cleanup:development-auth` task with development-only credentials, confirm zero `ci.*@example.test` users, then rerun. Cleanup failure is a release blocker.
- Smoke failure: stop promotion, inspect the named route/status, and follow [DEPLOYMENT_RUNBOOK.md](DEPLOYMENT_RUNBOOK.md).

References: [GitHub protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [Playwright CI](https://playwright.dev/docs/ci), [Supabase CLI CI](https://supabase.com/docs/guides/deployment/ci/testing), and [Netlify deploy contexts](https://docs.netlify.com/build/configure-builds/file-based-configuration/#deploy-contexts).
