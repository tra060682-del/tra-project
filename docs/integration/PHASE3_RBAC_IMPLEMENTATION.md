# Phase 3 RBAC implementation

## Implemented application layer

`src/lib/rbac.ts` defines the eight canonical roles, 22 named permissions, default role grants, multi-role permission union, labels, landing routes and the Finance bidding conflict rule. `src/lib/auth.ts` independently verifies identity, active status, roles and permissions on the server.

Protected auction and marketplace mutations now enter the shared boundary. Access administration calls audited RPC contracts rather than writing `user_roles` or profile status directly. The access screen is visible only to a resolved Super Admin. No email allow-list or client claim grants administration.

Self-service capabilities remain scoped:

- Artist: own profile, onboarding, artwork, legal acceptance and representation decisions through existing owner-aware RPC/RLS paths.
- Intermediary: own profile and explicitly approved, scoped, time-bounded representations.
- Collector: own account, wishlist and auction activity.
- Curator, Advisor and Finance: only named operational permissions; none can manage roles, platform settings or integrations.

## Proposed database layer (not applied)

Files in `docs/integration/sql/`:

1. `202611150100_phase3_role_enum.draft.sql` adds missing enum values in a separate transaction.
2. `202611150101_phase3_auth_rbac.draft.sql` adds account status, grants, overrides, invitations, representation revocation metadata, active-account guards, RLS and audited RPCs.
3. `202611150190_phase3_verify.draft.sql` contains read-only verification.
4. `202611150199_phase3_rollback.draft.sql` removes Phase 3 structures; enum values intentionally remain because safe removal requires a type rewrite.

The main migration requires the session setting `app.tra_phase3_target=ocstvctvmychromkcurw:approved-development-only`. It cannot run accidentally without explicit target approval. It extends existing tables and creates only new RBAC tables; it does not copy staging records or change auction concurrency functions.

## Administration invariants

- `roles.manage`, `settings.manage` and `integrations.manage` are Super Admin only.
- Admin cannot grant any role. Role changes require `roles.manage`.
- A Super Admin cannot change their own Super Admin membership.
- The last Super Admin cannot be revoked.
- Account status changes prohibit self-suspension and require a reason.
- Permission revocation overrides grants.
- Every role, status, invitation and representation change writes `audit_events`.
- No initial Super Admin is created by source or migration.
- Invitations are hashed, email-bound, verified-email-only, expiring and single-use; Super Admin is never invitational.

Database-level claims remain pending until the draft is reviewed, rehearsed against an isolated clone, and explicitly applied to development.

