# Phase 3 security test results

Result date: 2026-11-14 (Pacific/Auckland). Scope: branch `integration/emergent-phase3-auth-rbac`.

## Executed

| Check | Result |
|---|---|
| Next.js type generation and TypeScript | PASS |
| Unit suite | PASS — 26/26 |
| Integration suite | PASS — 21/21 |
| Eight roles and multi-role union | PASS |
| Super Admin-only protected permissions | PASS |
| Active/suspended status model | PASS (application model) |
| Finance bid conflict | PASS |
| Direct protected API boundary inspection | PASS |
| RPC-only access administration inspection | PASS |
| Migration target/audit/last-admin guards | PASS |
| Automatic Super Admin creation scan | PASS — absent |
| Representation revocation design | PASS |
| Next.js production build | PASS (4 GB Node heap; initial parallel run exhausted local memory) |
| Cloudflare development build | PASS — development guard and full five-stage vinext build |
| Browser suite | PASS — 24/24 with one worker |
| Phase 3 auth browser cases | PASS — 2/2 |
| Credential/secret pattern scan | PASS — no credential values detected; inventory role-name matches only |

## Not claimed

Database RLS/RPC enforcement is **not passed**. Docker is available, but no representative local Supabase stack was initialized and the Phase 3 proposals were intentionally not applied in accordance with the task restriction. Required database cases are: anonymous access, owner/cross-owner access, each of eight roles, multiple roles, revoke-wins, suspended active sessions, curator/admin escalation, last Super Admin, intermediary expiry/revocation, auction conflict and financial-table mutation. These must execute against an isolated representative database after explicit migration-rehearsal approval.

Live email verification, password delivery and session-expiry timing require a disposable Auth environment and mailbox harness. Source-level and browser flow coverage do not substitute for that environment.

