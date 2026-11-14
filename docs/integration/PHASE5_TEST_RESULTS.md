# Phase 5 test results

Executed on 2026-11-14 from `integration/emergent-phase5-dashboards`.

| Validation | Result |
|---|---|
| Next.js 16 type generation + TypeScript | PASS |
| Unit tests | **30/30 PASS** |
| Integration/static security tests | **36/36 PASS** |
| Playwright browser tests | **51/51 PASS** |
| Phase 3.5 disposable PostgreSQL rehearsal | **PASS: 39-table baseline, eight-role RLS/RPC, finance, auction and rollback** |
| Anonymous dashboard access cases | **6/6 PASS** |
| Responsive Phase 5 access-gate cases (1440/768/390) | **3/3 PASS** |
| Next.js production build | PASS, 48 generated pages / 47 page routes |
| Vinext compatibility | PASS, 100% (15 supported, 0 partial, 0 issues) |
| Cloudflare development environment validation | PASS with non-secret validation placeholders |
| Phase 4 approved-media boundary | PASS: 26/26 publishable local files |
| Credential scan | PASS: no high-confidence secret patterns in Phase 5 changes |

Commands: `npm.cmd run typecheck`, `npm.cmd test`, `npm.cmd run test:e2e`, `npm.cmd run test:phase35-database`, `npm.cmd run build`, and `npm.cmd run check:cloudflare` with the approved development project reference and non-secret validation values.

ESLint is not installed and there is no lint script in this repository, so a separate ESLint run could not execute. TypeScript, Next.js compilation and all existing executable suites passed; no dependency was added merely to manufacture a lint result.

The first Cloudflare validation attempt failed closed because required environment context was absent; the correctly scoped development validation then passed. No deployment occurred.

Browser tests cover public regressions, authentication gates, API origin rejection, disabled bidding and responsive overflow. Authenticated role UI tests were not executed against the shared development Supabase because Phase 5 was prohibited from creating/modifying test identities. Application authorization is covered by static/integration tests; current database enforcement is backed by Phase 3.5 disposable-clone results, not claimed as a new live RLS run.

Visual captures are in `docs/integration/screenshots/phase5`. Foundation screenshots use the explicit Phase 2 design preview. Protected route captures prove the unauthenticated boundary; no fake authenticated session or record was used.

