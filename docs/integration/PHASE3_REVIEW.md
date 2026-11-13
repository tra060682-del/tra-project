# Phase 3 review

Status: application layer implemented; database layer awaiting approval and execution.

## Completion summary

- All eight roles and the Phase 1 named-permission contract are implemented server-side, including multiple roles per user.
- Login and callback routing are role-aware; inactive accounts are signed out at login and rejected at protected operation boundaries.
- Protected bid/watchlist APIs and privileged Server Actions independently authorize identity, status and capability.
- Existing artist and intermediary registration/onboarding paths are preserved.
- Permission-aware Super Admin, Admin, Curator, Artist, Intermediary, Collector, Advisor and Finance workspace foundations are present.
- Role assignment/revocation, suspension/reactivation, invitation preparation and representation revocation call audited RPC contracts only.
- No identity linking or initial Super Admin assignment occurs automatically.
- Validation passed: TypeScript, 26 unit tests, 21 integration tests, 24 browser tests, Next.js production build, Cloudflare development build and credential scan.

## Pending database enforcement

The four Phase 3 SQL files are proposals under `docs/integration/sql`; none were added to `supabase/migrations`, run locally, or applied remotely. Until approval, account status defaults to active for compatibility, missing role enum values cannot be assigned, and access-administration RPCs are unavailable. Therefore database-level Phase 3 completion is blocked by design, while application-level integration is complete.

## Security risks / approval decisions

1. Approve or revise the role enum and permission seed.
2. Decide whether Finance membership should always prohibit bidding for a multi-role user (current least-privilege implementation: yes).
3. Approve the two-person initial Super Admin bootstrap procedure and MFA policy.
4. Approve invitation delivery/acceptance UX; Phase 3 only prepares hashed invitations.
5. Resolve identity-linking evidence, review and retention rules.
6. Rehearse migrations and rollback on an isolated clone, then execute the full RLS matrix. Do not infer database security from application tests.

## Phase 4 readiness

Ready for Phase 4 application work only after the pending database design decisions are approved. Applying migrations, bootstrapping a Super Admin, deploying, enabling payments/live auctions, merging to main, or promoting the 400 staged records remains out of scope.

