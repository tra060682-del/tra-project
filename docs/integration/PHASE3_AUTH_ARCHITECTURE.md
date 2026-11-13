# Phase 3 authentication architecture

Status: application implementation complete; database enforcement proposed but not applied.

## Trust boundaries

Supabase Auth remains the only identity provider. The browser supplies an HttpOnly session cookie; `@supabase/ssr` refreshes it in `proxy.ts`; server code calls `auth.getUser()` before trusting identity. Clerk identities are not imported or linked.

`src/lib/auth.ts` is the server boundary. It resolves all rows in `user_roles`, the profile account status, and the union of role permissions. Protected pages use `requireRole` or `requirePermission`; Route Handlers use `requireApiPermission`. A hidden control is never treated as authority. The database remains the final resource-ownership and concurrency boundary.

Account status is fail-closed once the Phase 3 column exists: only `active` can perform protected work. The current schema has no status column, so the application defaults an existing profile to active for backward compatibility until the proposal is approved. This limitation is explicitly tracked as pending database enforcement.

## Authentication flows

- Artist and intermediary registration keep their existing verified-email provisioning RPCs. Neither accepts a caller-selected role.
- Login validates credentials, resolves current roles/status server-side, signs an inactive user back out, and chooses a role-aware landing route.
- Callback code exchange uses PKCE, accepts only same-origin relative destinations, provisions only the explicit artist/intermediary intent, and otherwise derives a landing route from database roles.
- Logout invalidates the Supabase session. Password reset uses the existing non-enumerating response and PKCE callback.
- Profile updates are authenticated, owner-scoped updates to `profiles` and remain subject to RLS.
- Session refresh remains in `proxy.ts`; authorization is repeated at the operation boundary after refresh.

## Resource authorization

Global permissions follow `RBAC_SECURITY_MATRIX.md`. Artist ownership and intermediary scope are not converted into global permissions. Artist RPCs resolve the authenticated artist profile. The proposed `tra_representation_allows` function requires an active account, approved intermediary, approved relationship, unexpired dates, no revocation, and the requested scope. Revocation is row-locked, immediate and audited.

Auction bidding preserves the existing transactional `place_maximum_bid` RPC. The Route Handler additionally denies inactive accounts and Finance / Operations actors. The proposed active-actor trigger blocks suspended sessions at the database mutation boundary without replacing auction locking.

## Role-aware routes

| Role | Default route |
|---|---|
| Super Admin / Admin | `/admin` |
| Curator | `/admin/marketplace` |
| Artist | `/artist` |
| Intermediary | `/intermediary` |
| Collector | `/account` |
| Art Advisor / Finance / Operations | `/workspace` |

Multiple roles are supported. Landing precedence never grants capability; each destination re-authorizes independently.

