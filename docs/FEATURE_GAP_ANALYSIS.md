# tRA — The Real Art: feature gap analysis

Reviewed on 13 November 2026 against `feature/tra-artist-onboarding`.

The approved competitor feature catalogue referenced by the brief is not present in the repository. This assessment uses the explicit product brief, reviewed production-compatible schema and existing tRA decision records. Competitor-specific acceptance criteria remain an external input.

| Area | State after Phase 1 | Evidence | Remaining gap / dependency |
|---|---|---|---|
| Official branding | Implemented | Shared metadata, header, footer and artist registration use “The Real Art” | Historical documents may retain prior wording as evidence |
| Premium homepage | Implemented | Responsive editorial homepage and reference-derived design system | Approved original artwork photography is unavailable |
| Artwork discovery | Implemented with fallback | Database-backed published catalogue/detail routes; clearly labelled illustrative fallback | Taxonomy filters and pagination are Phase 2 |
| Collections | Partially implemented | Homepage presentation plus existing collection tables/RLS | Database-backed collection routes and approved media |
| Supabase Auth | Implemented | Artist/intermediary signup, email callback, login/logout and password recovery | Auth email templates/redirect allow-list are dashboard configuration |
| Artist onboarding | Implemented | Profile draft, current legal acceptance, submission and review status UI/RPCs | Approved legal content must be configured |
| Artwork submission | Implemented except upload | Declaration, original-artwork submission, status and admin remarks | Signed Cloudinary upload needs development credentials |
| Intermediaries | Implemented | Verified registration, profile review, scoped representation, artist consent and admin approval | Final intermediary terms require legal approval |
| Curatorial review | Implemented | Protected review queue; curator recommendation and admin final-decision split | Queue filters/notifications are Phase 2 |
| Admin operations | Implemented for Phase 1 | Artist, intermediary, representation, artwork, availability and enquiry views | Bulk actions/assignment are Phase 2 |
| Buyer enquiries | Implemented | Consented public form using existing security-definer RPC | Support routing/SLA configuration |
| Artwork availability | Implemented | Audited admin RPC with approved-media/price and commercial-lock checks | Reservation expiry automation is Phase 2 |
| Auction Lobby | Implemented, gated | Public lobby/detail, navigation and secure database module | Live bidding intentionally remains disabled |
| Collector accounts | Partial | Supabase Auth and bidder eligibility exist | Collector profile, wishlist and account centre are Phase 2 |
| Assisted commerce/offers | Partial | Enquiries, buyer, sale and payment-link schema | Offer negotiation UI/service is Phase 2 |
| Payments/settlements | Schema only | Existing sales, payment links, shipments and settlements | External provider and reconciliation operations |
| Certificates | Schema only | Existing certificate/private-file metadata | Artist/admin task UI and private Storage integration |
| Cloudinary | External integration required | Media schema and environment contract exist | Credentials, signed-upload service and approved assets |
| Analytics/content | Schema only | Pages, settings, taxonomies and audit events | CMS and privacy-safe analytics are Phase 2 |
| Cloudflare | Implemented | Vinext build and isolated environment validation | Development deployment is a separate release action |
| Automated validation | Implemented | Unit, integration, Playwright, disposable PostgreSQL, Next and Cloudflare builds | Authenticated browser CI needs protected synthetic users |

## Additive database work delivered

- Added `intermediary` and `curator` role values without changing identities.
- Added intermediary profiles and representation consent/history records.
- Added narrowly scoped, security-definer workflow RPCs.
- Reused existing artist, artwork, legal, enquiry, media, audit and status-history tables.
- Added RLS policies and grants without replacing production policies.

## External requirements

- Approved competitor feature catalogue.
- Development Cloudinary credentials and approved artwork/profile images.
- Final intermediary agreement and artwork declaration content.
- Named support routing and response SLA.
- Separate operational/legal approval before auction bidding can be enabled.
