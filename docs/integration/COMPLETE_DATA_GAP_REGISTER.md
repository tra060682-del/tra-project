# Complete data gap register

## Current evidence

The latest authorised read-only Supabase inspection on 2026-11-14 found **39 baseline public tables** and seven applied repository migrations. Phase 1, Phase 3 and Phase 6A draft migrations remain unapplied. The linked CLI target is named `tra-development` while its metadata reports environment `production`; that label discrepancy is a mandatory stop condition for any future mutation.

The completed staging import remains **400 records across 15 collections** and has not been promoted or repeated.

## Public versus staging

| Domain | Public approved state | Private staging evidence | Data gap / consequence |
|---|---|---:|---|
| Artworks | `artworks`: 0; `artwork_media`: 0 | 27 artworks | Catalogue/detail/home features cannot show real records. Emergent live previously showed 33, creating an unresolved 33/27 discrepancy. |
| Artists | `artist_profiles`: 0 | 13 artists | Directory/profile/attribution relationships are empty. |
| Collections | `collections`: 0 | no dedicated staged collection listed | Collection UI cannot be demonstrated; source collection configuration/content must be extracted separately. |
| Taxonomy | `taxonomies`: 2 | 85 terms | Full subject/artform/style/medium/category filtering cannot use approved relationships. |
| Auctions | no approved public preview rows demonstrated | 9 auctions, 1 bidder | Lobby/lot content is absent; live bidding remains intentionally disabled. |
| Journal | no approved public articles demonstrated | 44 articles | Journal index/detail and associated media are empty. |
| Legal | baseline legal structures exist, no staged promotion | 15 documents, 15 versions, 1 acceptance | Versioned legal centre cannot show source documents; acceptance identity needs verified linking. |
| Certificates | baseline structures/reads only | 1 certificate | Public verification remains disabled pending disclosure-safe RPC and token rules. |
| Platform settings | baseline setting surfaces | 4 settings | Source feature/content settings are not reconciled or approved. |
| Users/identity | Supabase Auth identities remain authoritative | 3 users | Clerk identities are not automatically linked; role/bootstrap decisions remain gated. |
| Analytics | private current model only | 25 events | Raw source analytics cannot be published; approved aggregates are absent. |
| Audit | protected baseline model | 106 audit rows | Historical source audit events cannot be treated as current authoritative events without identity/entity reconciliation. |
| Email | provider adapters disabled | 51 email-log rows | Historical rows do not prove delivery in the new architecture. |

## Full staging coverage

| Collection | Records | Required reconciliation before any promotion |
|---|---:|---|
| `analytics_events` | 25 | privacy model, salted identity, retention, aggregate/public boundary |
| `articles` | 44 | editorial approval, authorship, media rights, slug conflicts |
| `artists` | 13 | identity/attribution verification, consent, profile review |
| `artworks` | 27 | reconcile source count 33, ownership, price, taxonomy, rights, publication |
| `auctions` | 9 | preview approval, lots, terms, bidder/financial restrictions |
| `audit_logs` | 106 | actor/entity mapping and historical/non-authoritative label |
| `bidders` | 1 | verified Supabase identity, eligibility, terms |
| `certificates` | 1 | issuer/evidence/token/disclosure/revocation policy |
| `email_log` | 51 | historical-only status; no provider-delivery claim |
| `legal_acceptances` | 1 | verified identity and immutable body/hash snapshot |
| `legal_docs` | 15 | legal owner review and publication decision |
| `legal_versions` | 15 | immutable version/hash and effective-date review |
| `platform_settings` | 4 | discard QA residue; approve each operational value |
| `taxonomy_terms` | 85 | canonical values, active flags, multi-value relationships |
| `users` | 3 | approval-gated Clerk-to-Supabase matching; no duplicate identity |
| **Total** | **400** | remains private and unchanged |

## Unique data gaps

| Gap ID | Severity | Root cause | Required correction | Dependency | Acceptance/test |
|---|---:|---|---|---|---|
| DATA-001 | P0 | No approved public artwork/media rows | Reconcile and separately approve an auditable content promotion | rights, identities, Phase 1 content schema | exact approved row counts; anonymous RLS exposes only published rows |
| DATA-002 | P0 | 33 live-source works vs 27 staged | Establish authoritative six-record disposition | source export/product approval | signed reconciliation with no fabricated rows |
| DATA-003 | P0 | No approved public artists | Verify/link artist identities and review profiles | identity linking, consent | each published work resolves to approved artist |
| DATA-004 | P1 | Collections missing | Extract/map source collections and ordering | content schema | collection order and approved-only membership tests |
| DATA-005 | P1 | Taxonomy incomplete | Approve taxonomy and `artwork_taxonomies` relationships | Phase 1 migration | all source facets map without free-text drift |
| DATA-006 | P1 | Journal private/unapproved | Editorial and media-rights review | CMS schema, media | published articles render with authorised images |
| DATA-007 | P1 | Auction previews absent | Approve non-financial preview content | auction terms/content | no bid/payment enablement; preview RLS passes |
| DATA-008 | P1 | Legal content unpromoted | Legal owner approves versions/effective dates | legal publication RPC | immutable version/hash and correct acceptance |
| DATA-009 | P1 | Identity mismatch | Approval-gated Clerk evidence matching | Phase 3 identity policy | no email-only linking, duplicates, or role carryover |
| DATA-010 | P1 | Commerce schema/RPC absent | Approve/apply Phase 3 then Phase 6A proposal | 22-table proposal, policies | isolated tests repeated after development apply |
| DATA-011 | P2 | Settings not reconciled | Review each source setting and remove QA residue | admin approval | versioned/audited settings only |
| DATA-012 | P2 | Analytics cannot be reused directly | Define privacy-safe aggregates | retention/privacy approval | no direct identifiers/public raw events |
| DATA-013 | P2 | Audit/email history semantics differ | Import only if explicitly labelled historical | identity/entity mapping | current operations never rely on staged history |
| DATA-014 | P1 | Certificates lack approved public projection | Apply disclosure-safe RPC after policy approval | certificate migration | enumeration, revocation and field-filter tests |

## Migration order affecting parity

1. Re-verify/backup current baseline and resolve environment label.
2. Review/apply Phase 1 role enum and Phase 3 RBAC migration in development only after explicit approval.
3. Review remaining Phase 1 catalogue/content structures; never apply superseded Phase 1 permissions/commerce drafts.
4. Rebase/rehearse/apply Phase 6A commerce proposal only after Phase 3 enforcement.
5. Approve a separate, record-level content promotion; do not repeat the staging import.

This audit performs none of these actions.
