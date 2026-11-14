# Phase 5 RBAC validation

## Enforcement model

The eight Phase 3 roles remain unchanged. Multiple roles union permissions; active revocations override grants. Every dashboard page establishes an authenticated role or permission boundary, and each current mutation independently calls `requireRole` or `requirePermission`. Collector reads also filter by the authenticated user ID; artist and intermediary access relies on ownership/party RLS plus server validation.

| Control | Result |
|---|---|
| Anonymous dashboard access | Denied; 6 browser routes redirect to login |
| Suspended/deactivated/archived users | Denied centrally by `requireAuthContext` |
| Super Admin-only navigation | Conditional, with destination permission recheck |
| Self-escalation | No automatic bootstrap; mutation server-gated |
| Admin to Super Admin escalation | Phase 3 RPC gate closed; proposed SQL guards remain unapplied |
| Artist cross-owner access | Artist ID derived from authenticated profile; current RLS remains authoritative |
| Intermediary consent | Request → artist response → admin review; no implicit access |
| Intermediary delegated access | Disabled until representation-scope RLS is applied |
| Representation revocation | Server action fails closed until Phase 3 enforcement is approved/applied |
| Collector isolation | Queries use `buyer_id=user.id` or `user_id=user.id`; RLS remains required |
| Finance auction bidding | Prohibited by `mayBid`; no Phase 5 bid control is rendered |
| Audit modification | No edit/delete UI or action; read permission required |
| Role/status/invitation mutation | UI disabled and Server Actions require approval gate |
| Auction/payment mutation | UI disabled and server approval gates closed |

Static and browser tests prove the application boundary. Phase 3.5 separately exercised proposed database enforcement on a disposable PostgreSQL clone. Because the Phase 3 proposal is unapplied, Phase 5 does **not** claim its representation, suspension or new permission policies are active in development Supabase.

