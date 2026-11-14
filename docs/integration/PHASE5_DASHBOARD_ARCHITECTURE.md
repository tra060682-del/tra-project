# Phase 5 dashboard architecture

## Baseline verified

- Branch: `integration/emergent-phase5-dashboards`, based on verified Phase 4 commit `935c252`.
- Phase 3.5 is authoritative for the database baseline: **39 public tables**. The earlier Phase 0 reference to 40 tables is superseded.
- The 400 records remain in `emergent_staging`; no Phase 5 source reads that schema and no promotion command was run.
- Phase 1 and Phase 3 SQL proposals under `docs/integration/sql` remain unapplied. Existing application migrations through the Phase 1 marketplace and auction foundation are part of the rehearsed baseline, not newly applied by this phase.
- No remote database, production system, MongoDB, Clerk, Cloudflare deployment or payment provider was changed.

## Architecture

All five experiences use `DashboardLayout`, `DashboardMetrics` and the Phase 5 dashboard kit. The kit supplies headings, status badges, tables, feature states, disabled actions and responsive sections. It retains the Phase 2 ivory/cream/near-black/antique-gold tokens and Lora, DM Sans and IBM Plex Mono typography.

| Route | Primary experience | Server boundary |
|---|---|---|
| `/admin` | Super Admin / Admin overview | `requireRole(['super_admin','admin'])` |
| `/admin/access` | Super Admin inspection | `requirePermission('roles.manage')` |
| `/admin/marketplace` | Admin / Curator review | per-operation review permissions |
| `/admin/enquiries` | Admin / Art Advisor | `requirePermission('enquiries.manage')` |
| `/admin/content` | Admin / Curator | `requirePermission('content.manage')` |
| `/admin/finance` | Finance / Admin reporting | `requirePermission('reports.view')` |
| `/admin/audit` | authorised audit readers | `requirePermission('audit.view')` |
| `/admin/settings` | Super Admin | `requirePermission('settings.manage')` |
| `/artist` | Artist Studio | `requireRole(['artist'])` plus ownership/RLS |
| `/intermediary` | Intermediary | `requireRole(['intermediary'])` plus party/RLS |
| `/account` | Collector Account | `requireRole(['collector'])` plus identity filters/RLS |
| `/workspace` | Curator, Advisor, Finance modules | `requireAuthenticated` and permission-aware links; destination rechecks |

Authentication, active-account checks, multiple-role union and permission overrides remain centralised in `src/lib/auth.ts` and `src/lib/rbac.ts`. Hidden navigation is never treated as authorization.

## Approval gates

`src/lib/feature-gates.ts` fails closed unless an explicitly approved server environment flag is `true`. Phase 5 adds gates for Phase 3 database enforcement, live auctions, payments, outbound email and private media upload. Current role/status/invitation, representation revocation and auction administration actions cannot execute merely by posting directly to a Server Action.

## Data policy

Counts and records are real RLS-scoped reads. A query error produces an unavailable metric, never a zero disguised as a successful count. Unsupported contracts use `Blocked` or `Preview Only`; no staged or synthetic catalogue record enters a dashboard. Provider secrets are neither queried nor rendered.

## Responsive and accessibility design

Desktop uses a 260px sidebar and fluid content region. At 900px navigation becomes horizontally scrollable and a native-details mobile menu appears. At 620px feature grids and forms become single-column. Tables retain semantic captions and an intentional horizontal table scroller; the page itself does not overflow. Focus indicators, labels, disabled explanations, status text and keyboard-native controls target WCAG 2.2 AA.

## Visual evidence

Design-foundation captures: `screenshots/phase5/dashboard-foundation-{1440,768,390}.png`. Authentication-boundary captures: `protected-dashboard-gate-{1440,768,390}.png`. The foundation images are explicitly design-preview data, not claimed database records. Authenticated role screenshots require approved non-production fixtures and were not fabricated.

