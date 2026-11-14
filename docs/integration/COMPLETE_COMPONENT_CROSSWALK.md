# Complete component crosswalk

This crosswalk covers every authored Emergent frontend file detected by the source inventory. Generated shadcn primitives are grouped by file because the comparison target is the application behaviour, not a one-to-one framework file copy. The machine-readable appendix records every detected exported/local component, API call and test id.

Classification: **Exact**, **Partial**, **Missing**, **Redesigned**, **Disabled**, **Migration-blocked**, **Provider-blocked**, or **Media-blocked**.

## Global and shared components

| Emergent file/component group | Responsibility | Next.js equivalent | Classification | Material difference / action |
|---|---|---|---|---|
| `components/Header.tsx` | Desktop/mobile nav, account, search, bag | `src/components/header.tsx` | Partial / redesigned | Route set is mostly present; dimensions, drawer, search/bag behaviour and source ordering differ. |
| `components/Footer.tsx` | Footer navigation, newsletter, legal | `src/components/footer.tsx` | Partial | Source grouping/copy and newsletter interaction differ; outbound email remains disabled. |
| `components/ArtworkCard.tsx` | Catalogue artwork tile | catalogue browser/card markup | Partial / data-blocked | Structure exists, but no authorised populated catalogue proves metadata, badges and price parity. |
| `components/ImageUploader.tsx` | Artwork/journal upload | disabled upload surfaces, storage adapters | Provider-blocked | Private/public upload initiation is intentionally not active. |
| `components/ErrorBoundary.tsx` | Client error recovery | Next error/not-found handling | Redesigned | Framework boundary exists but source feedback/retry presentation is not preserved. |
| `components/Motion.tsx` | Reveal/transition helpers | CSS/reduced-motion styles | Partial | Motion language and timing are not fully cross-checked. |
| `components/TestBadge.tsx` | Explicit test-mode badge | feature/status badges | Partial | Semantics exist; placement and wording differ across financial/auction surfaces. |
| `components/RoomPreview.tsx` | View-in-room visualisation | none | Missing | Entire `/view-in-room` workflow is absent. |
| `components/SectionIntro.tsx` | Editorial section heading | repeated page markup/primitives | Partial | No single source-equivalent primitive; typography varies. |
| `components/FilterPills.tsx` | Status/category filters | catalogue filters/dashboard filters | Partial | Catalogue is close; dashboard filter behaviour is inconsistent. |
| `components/StatsCards.tsx` | Dashboard metrics | `DashboardMetrics` | Partial | Generic card system replaces source module-specific layout. |
| `components/AdminShell.tsx` / dashboard shell | Admin IA/navigation | `dashboard-layout.tsx` | Redesigned | Stronger route boundaries but not source visual/interaction parity. |
| `components/ui/*` | Button, input, select, tabs, dialog, table, badge, drawer, toast, tooltip, etc. | `ui/primitives.tsx`, `ui/interactive.tsx`, CSS | Partial | Core accessible primitives exist; many source variants/states are collapsed or use native alternatives. |
| `lib/api.ts` query/mutation feedback | Fetching, errors, invalidation | Server Components/actions and notices | Redesigned | Architectural replacement is valid; equivalent loading/error/success feedback is inconsistent. |
| `lib/format.ts` | money/date/media fallbacks | `lib` formatters and image registry | Partial / media-blocked | Exact copy/fallback imagery differs because 23 assets are quarantined. |

## Public page component groups

| Emergent file | Detected component group | Next.js equivalent | Classification | Gap |
|---|---|---|---|---|
| `pages/Home.tsx` | `Home`, trust/feature and editorial sections | `src/app/page.tsx` | Partial | Broad structure/tokens match; source text, populated modules and media do not. |
| `pages/Browse.tsx` | `Browse`, categories, sidebar filter groups, sort/grid | `/artworks`, `catalogue-browser.tsx` | Partial | Priority catalogue layout restored; zero public records prevents functional/visual completion. |
| `pages/ArtworkDetail.tsx` | `ArtworkDetail`, gallery, enquiry/offer panels | `/artworks/[slug]`, image/enquiry/commerce components | Partial | Reduced gallery/story/commerce and no resolvable public record. |
| `pages/Artists.tsx` | `Artists`, `ArtistProfile` | `/artists`, `/artists/[id]` | Partial / data-blocked | Directory/profile shells exist; populated layout and interactions unverified. |
| `pages/Collections.tsx` | `CollectionsIndex`, `CollectionDetail` | `/collections`, `/collections/[slug]` | Partial / data-blocked | Editorial modules and ordered artwork presentation incomplete. |
| `pages/Auctions.tsx` | auction index/cards/countdown | `/auctions`, `auction-card.tsx`, countdown | Partial / intentionally disabled | Preview is safe; source content and action density differ. |
| `pages/AuctionLot.tsx` | lot detail, watchlist, bidding | `/auctions/[id]`, bid/watch components | Partial / intentionally disabled | Live bid path remains closed; real source record absent. |
| `pages/JournalCenter.tsx` | index, article, categories, related content | `/journal`, `/journal/[slug]` | Partial / data-blocked | No public articles; editor/admin pieces are also incomplete. |
| `pages/Services.tsx` | About, Authenticity, ForArtists, HowToBid, five `RequestPage` modes | public service routes and `enquiry-page.tsx` | Partial / redesigned | Shared Next template loses page-specific source composition and some validation/feedback. |
| `pages/LegalCenter.tsx` | legal index/document/acceptance | `/legal`, `/privacy`, `/terms`, onboarding legal controls | Partial / migration-blocked | Generic version route and full versioned reading/acceptance centre missing. |
| `pages/CertCenter.tsx` | verification and certificate administration | `/certificates/verify`, admin gates | Disabled / migration-blocked | Correctly held until disclosure-safe RPC/RLS are approved. |
| `pages/AuthPages.tsx` | sign-in/sign-up wrappers | Supabase login/join/reset routes | Redesigned | Provider replacement is intentional; source shell and generic collector registration differ. |
| `pages/Commerce.tsx` public pieces | bag, payment verification, view-in-room | account commerce; no verify/view-in-room | Missing / blocked | Bag is gated; verify and room preview routes are absent. |

## Dashboard and administration component groups

| Emergent file | Detected components/modules | Next.js equivalent | Classification | Gap |
|---|---|---|---|---|
| `pages/Admin.tsx` | `Admin`, overview, artists, artworks, enquiries, users, review/reject/feature controls | `/admin`, `/admin/marketplace`, `/admin/enquiries`, `/admin/access` | Partial | Reads/reviews vary by applied schema; user mutations are gated; source tabbed IA differs. |
| `pages/AdminExtra.tsx` | commissions, media, payments, email log/health, integrations, user access | `/admin/commerce`, `/admin/integrations`, `/admin/access` | Partial / blocked | Mostly diagnostics, read-only or disabled; source operational actions absent. |
| `pages/AdminOps.tsx` | auctions, bidders, offers, orders, requests, certificates, journal, intermediaries, settings, audit, reports | multiple `/admin/*` routes | Partial / distributed | Several typed surfaces exist, but most state transitions depend on unapplied migrations/providers. |
| `pages/AiUsage.tsx` | AI usage/reporting | none | Missing / provider-blocked | No approved AI provider/usage persistence. |
| `pages/AttributionReview.tsx` | attribution queue/decision | none | Missing / migration-blocked | Evidence-based attribution workflow not implemented. |
| `pages/DiscoveryAdmin.tsx` | taxonomy, collections, featured content, search/discovery admin | limited content/settings surfaces | Missing/partial | Source has 20 API calls and 91 test ids; no equivalent complete admin centre. |
| `pages/PeopleAdmin.tsx` | users, roles, invitations, representation administration | `/admin/access`, marketplace representation review | Partial / migration-blocked | Inspection exists; secure role/invite/revocation mutations are gated. |
| `pages/ProfileCenter.tsx` | user/artist/intermediary profiles and preferences | `/profile`, artist/intermediary forms | Partial | Source unified profile centre is split and field/status coverage differs. |
| `pages/Studio.tsx` | artist overview, artworks, submission/draft, enquiries, offers, auctions, sales, shipping | `/artist`, `/artist/commerce` | Partial / migration/provider-blocked | Onboarding/submission core exists; upload/draft/commerce/fulfilment parity does not. |
| `pages/Intermediary.tsx` | profile, representations, delegated works, enquiries/sales | `/intermediary`, `/intermediary/commerce` | Partial / migration-blocked | Scoped data access is deliberately blocked pending database enforcement. |
| `pages/Commerce.tsx` account pieces | collector dashboard, wishlist, bag, offers, orders, certificates, notifications | `/account`, `/account/commerce`, `/wishlist` | Partial / migration-blocked | UI foundation exists; commerce RPCs/tables are unapplied and actions default disabled. |

## Component coverage totals

| Measure | Count |
|---|---:|
| Emergent page files inspected | 24 |
| Emergent shared/component files inspected | 26 |
| Next.js component files inspected | 17 |
| Next.js page routes inspected | 52 |
| Next.js server-action files inspected | 9 |

The complete file/component/test-id inventory is [`evidence/complete-parity-source-inventory.json`](evidence/complete-parity-source-inventory.json). It is the exhaustive appendix to this human-readable crosswalk and prevents small local components or dialogs from being silently omitted.

## Acceptance rule

“Partial” becomes “Exact equivalent” only after the source fields, states, keyboard behaviour, error feedback, responsive presentation, permission checks and real authorised persistence have each been demonstrated. A matching name, route, or card is insufficient.
