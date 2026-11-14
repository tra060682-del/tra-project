# Phase 4 public features

## Delivered

### Approved public data boundary

`src/lib/catalogue.ts` and `src/lib/public-content.ts` form a read-only public data layer. They query only:

- published artworks whose artist passes existing public RLS;
- approved artwork media;
- artist profiles that are both approved and explicitly public;
- published collections and their published artwork members; and
- published content pages in the `journal-` namespace.

Configuration errors and empty datasets return empty public states. There is no demo-record fallback and no reference to the 15 staging collections.

### Catalogue and discovery

- Addressable artwork search using `q`.
- Artist, price and sort filters reflected in the URL.
- Published result count and accessible empty state.
- Dynamic artwork metadata, canonical URL and `VisualArtwork` structured data.
- Approved multi-image gallery with responsive sizing, meaningful alt text and no Emergent-hosted dependency.
- Public artist and collection indexes plus detail routes.

### Editorial and service routes

- Published Art Journal index and detail routes.
- Legal/policy index and authenticity control explanation.
- Art Advisory, custom commission, corporate art, resale and general enquiry experiences.
- Existing server-only `tra_submit_enquiry` RPC, Zod validation, consent requirement, request-type labelling and safe redirect allowlist.
- Accurate confirmation: the enquiry is recorded for manual review; outbound email is not sent.
- Accurate disabled form when Supabase is not configured.

### Auction and certificate safety

- Auction lobby uses the approved Phase 2 visual system and licensed local artwork.
- Public auction data can only come from `public_auction_lots`.
- Phase 4 forces all returned lots to `biddingEnabled=false`.
- No real-money bid, automatic winner, payment or settlement path was added.
- Certificate verification does not query private certificate rows; it remains disabled until the public-token migration/RPC is approved and applied.

### Media rights

- All 26 Phase 2 approved Wikimedia assets remain the only files under `public/media/heritage`.
- The complete checksum/credit/licence/source register remains `PHASE2_APPROVED_MEDIA.json`.
- Eight public-domain/CC0 assets are used directly by reusable public components with visible credit and source links.
- The other 18 approved licensed files remain available in the local approved pool; no quarantined image was copied or referenced.
- All 23 unresolved images remain only in the verified Emergent archive.

### Search and SEO

- Static and dynamic canonical metadata.
- Dynamic artwork, artist, collection and journal titles/descriptions.
- Sitemap integration for approved indexable content.
- Environment-aware robots policy.
- Auction previews, certificate verification, unavailable dynamic records and design-preview routes are no-indexed or disallowed.
- Development without an approved canonical origin is deny-all for crawlers.

## Preserved functionality

- Existing Supabase Auth, callbacks and session handling.
- Artist and intermediary onboarding.
- Phase 3 server-side RBAC helpers and role-aware dashboards.
- Existing auction database concurrency controls.
- Existing Cloudflare environment guards and build configuration.
- Existing Privacy and Terms pages.

No database migration, staging promotion, Supabase write, infrastructure change, outbound email, deployment or merge was performed.

## Missing dependencies

1. Applied public certificate token/hash/RPC contract.
2. Approved typed service-request fields and workflow for advisory, commission, corporate and resale cases.
3. Applied Art Journal cover, excerpt, category, authorship, scheduling and relation fields.
4. Public slugs for artworks and artists if human-readable canonical URLs are required.
5. Published taxonomy joins for the full Emergent filter set.
6. Approved auction preview records and terms; no staged lot may substitute.
7. Outbound email provider and server-only Worker approval.
8. Rights approval for the quarantined 23 images.

