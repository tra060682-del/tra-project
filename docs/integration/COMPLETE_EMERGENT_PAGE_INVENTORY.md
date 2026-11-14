# Complete Emergent page inventory

Audit date: 2026-11-14. Authoritative sources: `frontend/src/App.tsx`, all files under `frontend/src/pages`, current Next.js `src/app`, and the browser/source evidence in `docs/integration/evidence`.

## Coverage result

- **37 declared Emergent routes** are accounted for (36 concrete patterns plus the wildcard).
- **24 Emergent page modules** and **52 Next.js page routes** were inspected.
- The catalogue-parity tip `8c328ef` is the latest safe baseline: it descends from Phase 6B.2 commit `e370d9b`; no later integration functionality is omitted.
- The live Emergent host was unavailable to Playwright, Computer Use, and the web fetcher during this audit. Live evidence therefore comes from the existing approved catalogue captures; other Emergent comparisons use the verified export and Phase 2 reference captures. All 28 selected Next.js surfaces were captured locally at 1440, 768, and 390 pixels.

## Public and account route crosswalk

| # | Emergent route | Source page/component | Next.js equivalent | Current classification | Audit finding |
|---:|---|---|---|---|---|
| 1 | `/` | `Home.tsx` | `/` | Partial equivalent | Section skeleton and tokens are close; live catalogue/content are empty and several source media/content details differ. |
| 2 | `/browse` | `Browse.tsx` | `/artworks` | Partial equivalent | Catalogue structure was restored, but approved public rows are zero, so the real 33-work display is absent. |
| 3 | `/category/:slug` | `Browse.tsx` | `/artworks?category=` | Partial equivalent | Query-based equivalent; source URL shape and populated category results are not equivalent. |
| 4 | `/art/:id` | `ArtworkDetail.tsx` | `/artworks/[slug]` | Partial / data-blocked | Gallery, enquiry and commerce surfaces exist in reduced form; no public artwork can resolve. |
| 5 | `/artists` | `Artists.tsx` | `/artists` | Partial / data-blocked | Directory shell exists; 13 staged artists remain private and public list is empty. |
| 6 | `/artists/:id` | `ArtistProfile` | `/artists/[id]` | Partial / data-blocked | Route exists but no public profile data demonstrates parity. |
| 7 | `/collections` | `CollectionsIndex` | `/collections` | Partial / data-blocked | Index shell exists; source editorial collection content is unavailable publicly. |
| 8 | `/collections/:slug` | `CollectionDetail` | `/collections/[slug]` | Partial / data-blocked | Route exists; artwork ordering/detail cannot be demonstrated with approved data. |
| 9 | `/auctions` | `Auctions.tsx` | `/auctions` | Partial / intentionally restricted | Preview-only lobby preserves the no-live-auction restriction; source populated previews are absent. |
| 10 | `/auctions/:id` | `AuctionLot.tsx` | `/auctions/[id]` | Partial / intentionally restricted | Lot presentation exists; real bidding and source data are unavailable by design. |
| 11 | `/journal` | `JournalCenter.tsx` | `/journal` | Partial / data-blocked | Index exists; 44 staged articles are not public. |
| 12 | `/journal/:slug` | `JournalArticle` | `/journal/[slug]` | Partial / data-blocked | Detail route exists; no approved article demonstrates typography, related content, or imagery. |
| 13 | `/advisory` | `Services.tsx RequestPage` | `/art-advisory` | Partial equivalent | Content and intake differ; submission depends on the approved enquiry contract. |
| 14 | `/commission` | `Services.tsx RequestPage` | `/commissions` | Partial equivalent | Service presentation exists; quote/milestone workflow is not active. |
| 15 | `/corporate` | `Services.tsx RequestPage` | `/corporate-art` | Partial equivalent | Intake shell exists; persistence/assignment/delivery are limited. |
| 16 | `/resale` | `Services.tsx RequestPage` | `/resale` | Partial equivalent | Intake shell exists; resale assessment workflow is incomplete. |
| 17 | `/contact` | `Services.tsx RequestPage` | `/contact` | Equivalent core submission | Only operation assessed equivalent; external delivery remains deliberately disabled. |
| 18 | `/about` | `Services.tsx About` | `/about` | Partial equivalent | Core content exists; source content order/media differ. |
| 19 | `/authenticity` | `Services.tsx Authenticity` | `/authenticity` | Partial equivalent | Public explanation exists; certificate/document integration is gated. |
| 20 | `/how-to-bid` | `Services.tsx HowToBid` | `/how-it-works` | Redesigned / partial | Route name and combined content differ from the source auction-specific journey. |
| 21 | `/for-artists` | `Services.tsx ForArtists` | `/for-artists` | Partial equivalent | Marketing page exists; source CTA flow points to different onboarding route. |
| 22 | `/legal` | `LegalCenter.tsx LegalIndex` | `/legal` | Partial / data-blocked | Index exists but 15 staged legal documents and 15 versions remain private. |
| 23 | `/legal/:key` | `LegalCenter.tsx LegalDocument` | `/legal`, `/privacy`, `/terms` | Partial / route mismatch | Selected static routes exist; generic versioned document route is missing. |
| 24 | `/verify-certificate` | `CertCenter.tsx VerifyCertificate` | `/certificates/verify` | Intentionally disabled | Disclosure-safe RPC and migration are not approved/applied. |
| 25 | `/verify` | `Commerce.tsx VerifyPayment` | none | Missing / provider-blocked | Payment verification journey is not exposed. |
| 26 | `/verify/:number` | `Commerce.tsx VerifyPayment` | none | Missing / provider-blocked | Number-based payment verification route is absent. |
| 27 | `/view-in-room` | `Commerce.tsx ViewInRoom` | none | Missing | Source visualisation page has no Next.js route. |
| 28 | `/bag` | `Commerce.tsx Bag` | `/account/commerce` | Partial / migration-blocked | Bag module is protected and disabled until commerce RPCs are applied. |
| 29 | `/account` | `Commerce.tsx Account` | `/account`, `/account/commerce` | Partial equivalent | Account is split across routes and most commerce modules are gated. |
| 30 | `/dashboard` | `Commerce.tsx DashboardRedirect` | `/workspace` | Redesigned / partial | Permission-aware routing is stronger, but source landing/role journey differs. |
| 31 | `/intermediary` | `Intermediary.tsx` | `/intermediary` | Partial / migration-blocked | Profile/request UI exists; scoped artwork, enquiry, fulfilment and revocation enforcement are blocked. |
| 32 | `/join` | `Join.tsx` | `/join-as-artist`, `/join-as-intermediary` | Partial / split route | Artist journey is preserved in a different route; source intermediary mode differs. |
| 33 | `/studio` | `Studio.tsx` | `/artist`, `/artist/commerce` | Partial / migration-blocked | Core onboarding/submission exists; uploads, drafts, offers, shipping and settlements are incomplete/gated. |
| 34 | `/admin` | `Admin.tsx` plus admin centres | `/admin/*` | Partial / distributed | Next separates modules; many source controls are read-only, preview-only, or blocked. |
| 35 | `/sign-in/*` | `AuthPages.tsx` + Clerk | `/login`, `/forgot-password`, `/reset-password` | Intentional provider replacement | Supabase Auth replaces Clerk; visual/user-feedback parity remains incomplete. |
| 36 | `/sign-up/*` | `AuthPages.tsx` + Clerk | `/join-as-artist`, `/join-as-intermediary` | Partial / provider replacement | No generic collector registration journey equivalent was demonstrated. |
| 37 | `*` | `NotFound` | Next.js not-found | Equivalent concept | Framework-specific presentation differs. |

## Embedded page modules not visible in the route declaration

These are first-class application surfaces rendered under `/admin`, `/studio`, `/account`, or `/intermediary` and are included in the dashboard register: `AdminExtra`, `AdminOps`, `AiUsage`, `AttributionReview`, `CertCenter`, `DiscoveryAdmin`, `PeopleAdmin`, `ProfileCenter`, `JournalCenter`, `LegalCenter`, and the commerce/account panels.

## Next.js-only routes

The 52-route Next.js tree also contains architecture- or phase-specific routes with no direct Emergent page: `/access-denied`, `/accept-invitation`, `/admin/access`, `/admin/integrations`, `/admin/finance`, `/design-preview`, `/profile`, `/wishlist`, and the role-specific `/.../commerce` routes. These are acceptable only where they preserve a source workflow or add security diagnostics; they are not evidence of Emergent parity by themselves.

## Evidence

- Machine-readable source inventory: [`evidence/complete-parity-source-inventory.json`](evidence/complete-parity-source-inventory.json)
- Local browser summary: [`evidence/complete-parity-browser-summary.json`](evidence/complete-parity-browser-summary.json)
- Current local captures: [`evidence/complete-parity-screenshots`](evidence/complete-parity-screenshots)
- Approved Emergent catalogue captures: [`screenshots/parity-audit`](screenshots/parity-audit)
- Verified Phase 2 homepage references: [`screenshots/phase2/reference`](screenshots/phase2/reference)
