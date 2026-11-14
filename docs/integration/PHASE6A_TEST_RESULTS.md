# Phase 6A test results

## Executed validation

| Check | Exact result |
|---|---|
| Next.js type generation + TypeScript | PASS |
| Unit tests | **40 passed, 0 failed** (10 Phase 6A) |
| Integration/static security tests | **44 passed, 0 failed** (8 Phase 6A) |
| Playwright Chromium | **59 passed, 0 failed** (8 Phase 6A) |
| Responsive gates | PASS at 1440, 768 and 390 px |
| Accessibility assertions | PASS within Playwright suite; labelled controls, keyboard/dialog and overflow checks |
| Next.js 16.4.5 production build | PASS; 52 static pages generated |
| Cloudflare development validation | PASS; vinext **100% compatible**, 15 supported, 0 partial, 0 issues |
| Disposable database rehearsal | PASS; forward, RLS/grants, transactions, finance integrity, rollback |
| Credential scan | PASS; no value/private key found |
| Approved-media boundary | PASS; exactly 26 public heritage files, no quarantined copy |

The aggregate application suite is 84 Node tests plus 59 browser tests: **143 passed, 0 failed**. Database assertions are additional SQL/harness checks and are not inflated into that count.

## Database coverage

The isolated Supabase/PostgreSQL run used the development schema-only dump, never development or production connections for execution. It exercised anonymous denial, active-account checks, ownership, Finance restrictions, offer stale state and acceptance conflict, reservation conflict, payment idempotency, append-only balanced ledger, certificate disclosure, grants and rollback to the 39-table baseline.

## Limitations

- No live provider test was possible or appropriate: payment, email, storage scanning and courier providers are unselected and disabled.
- No authenticated browser fixture was created because doing so would mutate the development Auth/database; authorization is covered by application tests and the isolated database run.
- ESLint is not configured in this repository (no dependency/script), so TypeScript, Next compilation and test lint-like static assertions are reported instead; no false ESLint pass is claimed.
- The existing Next development process was reused by the Playwright runner; the runner reported PID 17168 and completed cleanly. Process command-line inspection is restricted in this environment.

