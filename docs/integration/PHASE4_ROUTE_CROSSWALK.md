# Phase 4 public route crosswalk

## Authority and release boundary

The Emergent export was re-verified before implementation: **388/388 `FILES.sha256` entries matched**. `frontend/src/App.tsx`, the public page source, executable tests, and the Phase 1 API crosswalk were treated as authoritative. No staged collection is queried by any route below. No Phase 1 or Phase 3 SQL draft was applied.

Status definitions:

- **Fully functional** — the route and its required approved contract work without a Phase 4 placeholder.
- **Functional with limitations** — the route uses an existing approved contract but a later schema/content decision limits the experience.
- **Preview only** — presentation is available, but operational actions are deliberately disabled.
- **Blocked pending approval** — the page explains why the operation cannot safely run.

| Public capability | Emergent route | Next.js route | Data/operation contract | Status | Limitation or safety boundary |
|---|---|---|---|---|---|
| Homepage | `/` | `/` | Licensed local media; links to approved routes | Fully functional | Heritage references are editorial and explicitly not inventory |
| Artwork catalogue | `/browse`, `/category/:slug` | `/artworks` | `artworks`, `artist_profiles`, approved `artwork_media` under existing RLS | Functional with limitations | Search, artist, budget and sort are available; taxonomy filters wait for approved taxonomy publication fields |
| Artwork detail/gallery | `/art/:id` | `/artworks/[slug]` | Published artwork UUID and approved media only | Functional with limitations | Route segment is the existing artwork UUID because the current table has no public slug |
| Artist directory | `/artists` | `/artists` | Approved + `public_visible` artist profiles | Functional with limitations | Empty until profiles have approval and explicit visibility consent |
| Artist profile | `/artists/:id` | `/artists/[id]` | Public artist profile and its published artworks | Functional with limitations | UUID route remains until an additive public slug is approved |
| Curated collections | `/collections` | `/collections` | Published `collections`, public `collection_artworks`, published artworks | Functional with limitations | No staged collection promotion |
| Collection detail | `/collections/:slug` | `/collections/[slug]` | Existing collection slug and approved members | Fully functional | Empty collection state is honest when no public work qualifies |
| Auction lobby | `/auctions` | `/auctions` | Existing `public_auction_lots` view | Preview only | No fabricated fallback; page is no-indexed; bidding, winners, payment and settlement disabled |
| Auction lot | `/auctions/:id` | `/auctions/[id]` | Approved public auction view | Preview only | Direct unknown IDs return 404; all Phase 4 lots force `biddingEnabled=false` |
| Art Journal | `/journal` | `/journal` | Published `content_pages` with `journal-` slug namespace | Functional with limitations | Rich article metadata, relations and workflow wait for unapplied additive design |
| Journal article | `/journal/:slug` | `/journal/[slug]` | Published namespaced content page | Functional with limitations | Plain safe text rendering; no staged articles or unsafe HTML rendering |
| Legal index | `/legal` | `/legal` | Existing public Privacy and Terms plus current authenticity explanation | Fully functional | Commerce/live-auction terms are not claimed active |
| Privacy | `/legal/privacy` | `/privacy` | Existing Next.js public document | Fully functional | Existing approved content preserved |
| Terms | `/legal/terms` | `/terms` | Existing Next.js public document | Fully functional | Existing approved content preserved |
| Authenticity policy | `/authenticity` | `/authenticity` | Current certificate control description | Fully functional | Clearly identifies unapplied public verification contract |
| Certificate verification | `/verify-certificate` | `/certificates/verify` | Proposed disclosure-safe token RPC | Blocked pending approval | No query against private `certificates`; token-hash/RPC migration is unapplied |
| Art Advisory | `/advisory` | `/art-advisory` | Existing `tra_submit_enquiry` RPC | Functional with limitations | Secure record creation only; no outbound email |
| Custom commissions | `/commission` | `/commissions` | Existing `tra_submit_enquiry` RPC with server-validated request label | Functional with limitations | Dedicated commission workflow and quoting are Phase 5+ scope |
| Corporate art | `/corporate` | `/corporate-art` | Existing `tra_submit_enquiry` RPC with server-validated request label | Functional with limitations | Dedicated service-request schema is not applied |
| Resale | `/resale` | `/resale` | Existing `tra_submit_enquiry` RPC with server-validated request label | Functional with limitations | Submission is not represented as appraisal or consignment acceptance |
| Contact | `/contact` | `/contact` | Existing `tra_submit_enquiry` RPC | Fully functional | A success message says the record was stored and explicitly says no email was sent |
| Sitemap | — | `/sitemap.xml` | Static approved routes plus live public records | Fully functional | Preview auction and certificate routes are excluded |
| Robots | static file | `/robots.txt` | Environment-aware metadata route | Fully functional | No canonical site origin means deny-all; protected, preview and API paths are disallowed |

## Superseded route assumptions

- The Phase 2 illustrative catalogue fallback is superseded. Public catalogue failures now return an empty state, never sample inventory.
- The Phase 2/3 fabricated auction fallback lots are superseded. Only the approved public auction view may produce a lot.
- Emergent Clerk routes remain retired in favour of the existing Supabase Auth routes.
- Emergent `/verify` commerce verification is not recreated because its required public disclosure contract is not approved.

