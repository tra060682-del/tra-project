# Complete dashboard gap register

## Summary

All five primary layouts exist in Next.js, but none is a complete demonstrated Emergent equivalent. Authentication gates and least-privilege restrictions are preserved; this audit does not recommend weakening them. Database-level parity remains blocked by unapplied Phase 1/3/6A migrations.

## Super Admin and Admin

| Gap ID | Source navigation/workflow | Required data/actions | Current equivalent | Status | Required correction / test |
|---|---|---|---|---|---|
| DASH-001 | Admin overview/stats | users, artists, works, auctions, enquiries, orders | `/admin` | Partial | Match source cards/queues; unavailable metrics must remain explicit. Test real authorised reads. |
| DASH-002 | Artist review | application, docs, notes, approve/change/reject | `/admin/marketplace` | Partial | Reconcile every source field/dialog and legal gate; test approve/deny and cross-role access against applied RPC/RLS. |
| DASH-003 | Artwork review/publication | media, taxonomy, price, notes, feature/publish | `/admin/marketplace` | Partial | Add source media/taxonomy/revision detail; preserve rights and publication checks. |
| DASH-004 | Enquiry inbox | filters, assignment, notes, status, follow-up | `/admin/enquiries` | Limited | Assignment/notes/outbound delivery absent; add audited mutation and delivery evidence. |
| DASH-005 | User directory/access | roles, status, invitations, access dialog | `/admin/access` | Migration-blocked | Apply approved Phase 3 structures first; test no self-escalation/last-super-admin/suspension. |
| DASH-006 | Collections/discovery | taxonomy, curated ordering, featured content | `/admin/content` and public reads | Missing/partial | Port `DiscoveryAdmin`; test ordering and approved-work-only publication. |
| DASH-007 | Auction administration | auction/lot config, bidders, readiness, audit | `/admin/auctions` | Preview only | Match source controls behind server gates; never enable live mode without approval. |
| DASH-008 | Offers/orders | review, forward, transitions, fulfilment | `/admin/commerce` | Migration-blocked | Apply transactional commerce schema/RPCs; test concurrency, ownership and idempotency. |
| DASH-009 | Payments/refunds/settlements | evidence, ledger, reconcile, export | `/admin/finance`, integrations | Provider/migration-blocked | Preserve append-only ledger; require verified provider evidence and finance RBAC. |
| DASH-010 | Requests/commissions | assign artist, quote, status history | enquiry/service surfaces | Missing/partial | Implement source state machine and audit trail; no false email/quote success. |
| DASH-011 | Certificates | issue, revoke, verify, audit | disabled verification/admin surfaces | Migration-blocked | Apply disclosure-safe contract; test enumeration and private-field filtering. |
| DASH-012 | Journal/legal CMS | draft/review/publish/version | `/admin/content` | Limited | Port source editors and immutable legal publication rules. |
| DASH-013 | Media review | uploads, rights, approval | no complete equivalent | Provider/migration-blocked | Signed upload, scanning, ownership and rights review required. |
| DASH-014 | Integrations/email health | provider status, logs, retry, cron | `/admin/integrations` | Diagnostic only | Keep secrets server-side; add only after approved sandbox connectivity. |
| DASH-015 | AI usage/assist | descriptions, taxonomy, journal draft, usage | none | Provider-blocked | Separate approval; label unverified output and audit usage. |
| DASH-016 | Attribution review | evidence, decision, immutable history | none | Missing/migration-blocked | Port queue and append-only decisions without changing original attribution. |
| DASH-017 | Settings/feature flags | brand, fees, auction/payment flags | `/admin/settings` | Preview/limited | Mutations need audited/versioned RPC; browser flags may never activate protected features. |
| DASH-018 | Audit/reports | filtered audit, CSV, financial verification | `/admin/audit`, `/admin/finance` | Partial | Match source filters/exports; protect private fields and distinguish test figures. |

## Artist Studio

| Gap ID | Workflow path | Source fields/actions | Current equivalent | Status | Required correction / test |
|---|---|---|---|---|---|
| DASH-019 | Overview | profile status and counts | `/artist` | Partial | Match source greeting, metrics, review notes and tabs with real owned data. |
| DASH-020 | Profile/onboarding | biography, statement, specialisms, legal | artist join/profile | Core functional, visual partial | Reconcile field set, drafts and feedback without bypassing verification. |
| DASH-021 | Artwork submission | title, style, medium, price, dimensions, year, subject, origin, images, declarations | artist actions/forms | Partial | Restore exact source contract; secure upload remains blocked. |
| DASH-022 | Draft/edit lifecycle | draft, submit, changes, approve/reject/publish/sold | reduced action path | Limited | Add compatible state mapping and optimistic-concurrency tests. |
| DASH-023 | Media upload | primary/extra images and metadata | disabled | Provider-blocked | Signed purpose-bound upload, scanner, rights declaration and ownership checks. |
| DASH-024 | Enquiries | authorised buyer interest | limited/empty | Partial | Implement owned projection and feedback, excluding private collector fields. |
| DASH-025 | Offers | accept/reject/counter | `/artist/commerce` | Migration-blocked | Use transactional offer RPC and version checks. |
| DASH-026 | Auctions | submit/track eligible works | preview only | Migration/approval-blocked | Preserve launch gate and source statuses. |
| DASH-027 | Sales/shipping | orders, carrier, tracking, delivery | commerce foundation | Migration/provider-blocked | Apply order/shipping schema; protect addresses and documents. |
| DASH-028 | Settlement/certificates | payable status, issue certificate | preview/blocked | Migration-blocked | Implement artist-issued certificate and read-only settlement projections. |

## Intermediary

| Gap ID | Workflow | Current equivalent | Status | Required correction / test |
|---|---|---|---|---|
| DASH-029 | Professional profile/review | `/intermediary` | Core partial | Match source fields/status/history and review feedback. |
| DASH-030 | Representation request/consent | request UI and admin review | Partial | Artist consent UI/history incomplete; test explicit consent and no implicit activation. |
| DASH-031 | Scope/expiry/revocation | displayed scope; revocation gated | Migration-blocked | Database-enforced immediate loss required; test expired/revoked access directly. |
| DASH-032 | Delegated artwork drafts | feature gates | Blocked | Add only with scoped RLS/RPC; never impersonate artist credentials. |
| DASH-033 | Enquiries/sales/shipping | feature gates | Blocked | Minimum authorised projections required. |
| DASH-034 | Commission status | feature gate | Policy/migration-blocked | Snapshot entitlement at sale under approved policy. |

## Collector Account

| Gap ID | Workflow | Current equivalent | Status | Required correction / test |
|---|---|---|---|---|
| DASH-035 | Account overview/profile | `/account`, `/profile` | Partial | Recreate source tabs/summary while keeping Supabase identity management. |
| DASH-036 | Wishlist/recently viewed | `/wishlist`, `/account/commerce` | Migration-blocked | Apply owned persistence; test isolation and clear/history limits. |
| DASH-037 | Bag/reservations | commerce page | Migration-blocked | Atomic original-art inventory controls required. |
| DASH-038 | Enquiries | contact/enquiry action | Partial | Add own history/status projection and safe responses. |
| DASH-039 | Offers/counteroffers | commerce UI/contracts | Migration-blocked | Transactional state machine and amount validation required. |
| DASH-040 | Orders/payments/refunds | preview modules | Provider/migration-blocked | Verified provider events and immutable price/ledger snapshots required. |
| DASH-041 | Auction participation | watch/bid foundation | Intentionally disabled | Retain finance restriction and launch gate; test bidder eligibility in isolation. |
| DASH-042 | Certificates | disabled verification | Migration-blocked | Secure owned document access and filtered public verification required. |
| DASH-043 | Notifications/preferences | foundation only | Migration/provider-blocked | Persist preferences/deduplication; security notices need separate policy. |

## Cross-dashboard acceptance

Each protected action must pass authentication, active account, permission, ownership/representation scope, approval state, validation and audit checks on the server. Browser-hidden controls are never sufficient. Database-level enforcement cannot be reported complete until approved migrations are applied and the RLS/RPC tests run against representative PostgreSQL.
