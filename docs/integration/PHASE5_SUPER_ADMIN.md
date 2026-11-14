# Phase 5 Super Admin

Implemented modules: real RLS-scoped platform metrics, account/role inspection, audit history, settings contract inspection, finance reporting and permission-aware navigation. Emergent references are `Admin.tsx`, `PeopleAdmin.tsx`, `AdminOps.tsx` and `AdminExtra.tsx`.

Privileged mutations deliberately remain unavailable. Role changes, account suspension/reactivation and invitations are blocked in the interface and by `requireApprovalGate('phase3-database-enforcement')`. The application does not auto-create or infer a Super Admin, and no email allow-list exists. Settings values are read without exposing provider credentials; mutation awaits an audited settings RPC. Authentication-event projection, notification analytics and payment activity show unavailable/preview states rather than invented counts.

Routes: `/admin`, `/admin/access`, `/admin/settings`, `/admin/audit`, `/admin/finance`. Every route requires either a Super Admin role or the exact named permission.

