# API endpoint crosswalk

Status: Phase 1 contract; no application endpoint was changed.

## Authoritative inventory correction

The source declares **214 business route operations** across `backend/server.py` and `backend/routers/*.py`. The earlier 128 figure counted only decorators named `router`/`api_router` and omitted operations declared on `admin_router` and `users_router`. The exported OpenAPI file lists 89 operations and is also superseded. This document accounts for all 214 source operations. Clerk adds two compatibility routes outside the business inventory: `GET /api/clerk/config` and multi-method `/api/__clerk/{path}`; both are obsolete under Supabase Auth.

## Contract conventions

- All new request bodies are validated with Zod; database constraints remain authoritative.
- Public reads use Server Components or cacheable Route Handlers. Authenticated mutations use Server Actions/Route Handlers and RLS; concurrency or money transitions use transactional RPCs.
- `permission(x)` means the caller must possess the named permission; role defaults are defined in `RBAC_SECURITY_MATRIX.md`.
- Error codes shown are explicit source exceptions. Zod/Pydantic-equivalent validation adds 400/422; unexpected errors are sanitized 500 responses with correlation IDs.

Test legend: **P** anonymous/public, **A** authenticated, **R** role/permission/RLS, **V** validation/error, **X** cross-user ownership, **I** integration/persistence, **T** transaction/concurrency/money, **W** webhook signature/idempotency, **C** cron authentication/idempotency.

## Business-rule catalogue

| Code | Required invariant |
|---|---|
| RBAC | Permission checked server-side and again by RLS/RPC; UI visibility is not authorization. |
| IDENT | Verified Supabase identity; no email-only privilege grant; suspension and last-Super-Admin rules apply. |
| ARTIST | Artist owns profile/artwork; review/publication fields are staff-only; legal acceptance gates submission. |
| REP | Active, administrator-approved representation and current artist-granted scope are required for delegated actions; revocation is immediate. |
| PUBLIC | Only approved/published records and approved media are public; inputs are bounded and escaped. |
| DISC | Taxonomy values must exist and be active; analytics use salted visitor hashes and reject direct identifiers. |
| AUC | Database time, eligibility, terms, increments, proxy ceilings, idempotency, reserve and anti-sniping are enforced in PostgreSQL. |
| COM | Availability/reservation and offer/order transitions are atomic; amounts are integer paise; actors may see only their side. |
| PAY | Provider signatures, exact amount/currency, event idempotency and append-only ledger rules are mandatory. |
| CERT | Private originals stay private; public verification exposes an allow-listed projection; versions are append-only. |
| LEGAL | Published versions are immutable; acceptance stores version, body/hash snapshot and verified user. |
| JRN | Draft/review/publish transitions are permissioned; artist quotations require recorded approval. |
| MEDIA | Signed upload constraints cover owner, MIME, bytes and purpose; approval is separate; deletion is blocked when referenced. |
| PROFILE | Owner-only updates exclude roles/review/finance administration; identity documents are private. |
| SERVICE | Consent, rate limiting and assignment boundaries apply to enquiries, newsletter and service requests. |
| COMM | Quote/action/payment transitions are state-machine controlled and ledger-backed. |
| AI | Server-held key, rate limit, prompt/output bounds, unverified labels and usage audit are required. |
| ATTR | Decisions are append-only, require evidence, preserve original attribution and cannot impersonate the placeholder reviewer. |
| CRON | Worker-only secret/service binding, replay key and job lock; acknowledge only after durable enqueue. |

## admin

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 1 | GET | `/api/admin/artists` | permission('artists.review') | none | list[Artist] | artists | RBAC; source `admin_artists`; explicit validation/default 4xx/5xx | Partial: marketplace review page/actions | RSC/typed Route Handler under RLS | V,A,R |
| 2 | PATCH | `/api/admin/artists/{id}/status` | permission('artists.review') | id:str=required; body:ReviewUpdate=required | Artist | artists | RBAC; source `review_artist`; explicit 400, 404 | Partial: marketplace review page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 3 | GET | `/api/admin/artworks` | permission('artworks.review') | none | list[Artwork] | artworks | RBAC; source `admin_artworks`; explicit validation/default 4xx/5xx | Partial: marketplace review page/actions | RSC/typed Route Handler under RLS | V,A,R |
| 4 | PATCH | `/api/admin/artworks/{id}/featured` | permission('artworks.review') | id:str=required | Artwork | artworks | RBAC; source `feature_artwork`; explicit 404 | Partial: marketplace review page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 5 | PATCH | `/api/admin/artworks/{id}/status` | permission('artworks.review') | id:str=required; body:ReviewUpdate=required | Artwork | artworks, media | RBAC; source `review_artwork`; explicit 400, 404 | Partial: marketplace review page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 6 | GET | `/api/admin/enquiries` | permission('enquiries.manage') | none | list[Enquiry] | enquiries | RBAC; source `admin_enquiries`; explicit validation/default 4xx/5xx | Partial: marketplace review page/actions | RSC/typed Route Handler under RLS | V,A,R |
| 7 | PATCH | `/api/admin/enquiries/{id}/status` | permission('enquiries.manage') | id:str=required; body:EnquiryStatusUpdate=required | Enquiry | enquiries | RBAC; source `enquiry_status`; explicit 404 | Partial: marketplace review page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 8 | GET | `/api/admin/stats` | staff | none | AdminStats | artists, artworks, auctions, bidders, enquiries, intermediaries, offers, orders, requests | RBAC; source `stats`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 9 | GET | `/api/users` | permission('users.view') | none | UserList | users | RBAC; source `list_users`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 10 | GET | `/api/users/{user_id}/access` | permission('users.manage') | user_id:str=required | implicit JSON | users | RBAC; source `get_access`; explicit 404 | None | RSC/typed Route Handler under RLS | V,A,R |
| 11 | PATCH | `/api/users/{user_id}/access` | permission('users.manage') | user_id:str=required; body:AccessIn=required | implicit JSON | users | RBAC; source `set_access`; explicit 400, 403, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 12 | PATCH | `/api/users/{user_id}/role` | permission('users.manage') | user_id:str=required; body:RoleIn=required | UserRow | users | RBAC; source `set_role`; explicit 403, 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |

## ai

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 13 | POST | `/api/admin/ai/artworks/{id}/taxonomy-suggestions` | permission('artworks.review') | id:str=required | TaxonomySuggestion | artworks, taxonomy_terms | AI; source `suggest_taxonomy`; explicit 404, 502, 503 | None | Server-only Route Handler; OpenAI; usage audit | V,A,R,I |
| 14 | POST | `/api/admin/ai/journal-draft` | permission('content.manage') | body:JournalDraftIn=required | implicit JSON | artists, artworks | AI; source `draft_article`; explicit validation/default 4xx/5xx | None | Server-only Route Handler; OpenAI; usage audit | V,A,R,I |
| 15 | GET | `/api/admin/ai/usage` | permission('audit.view') | kind:str=''; q:str=''; days:int=0; page:int=1 | AiUsagePage | ai_generations, artworks | AI; source `ai_usage`; explicit validation/default 4xx/5xx | None | Server-only Route Handler; OpenAI; usage audit | V,A,R |
| 16 | POST | `/api/ai/artwork-description` | authenticated | body:DescriptionDraftIn=required | implicit JSON | artists, intermediaries | AI; source `draft_description`; explicit 403 | None | Server-only Route Handler; OpenAI; usage audit | V,A,R,I |
| 17 | POST | `/api/artworks/{id}/ask` | public | id:str=required; body:ArtworkQuestionIn=required; request:Request=required | implicit JSON | ai_chats, ai_generations, artists, artworks | AI; source `ask_artwork`; explicit 404, 409, 429 | Partial: server-side catalogue | Server-only Route Handler; OpenAI; usage audit | V,P,I |
| 18 | GET | `/api/artworks/{id}/ask/{session_id}` | public | id:str=required; session_id:str=required | ArtworkChat | ai_chats, artworks | AI; source `chat_history`; explicit 404 | Partial: server-side catalogue | Server-only Route Handler; OpenAI; usage audit | V,P |

## attribution

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 19 | GET | `/api/admin/attribution-reviews` | permission('artworks.review') | none | list[AttributionReview] | articles, artworks, attribution_reviews, platform_settings | ATTR; source `list_reviews`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 20 | POST | `/api/admin/attribution-reviews/{id}/decision` | permission('artworks.review') | id:str=required; body:AttributionDecisionIn=required | AttributionReview | articles, artworks, attribution_reviews, platform_settings | ATTR; source `decide`; explicit 400, 403, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |

## auctions

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 21 | GET | `/api/admin/auctions` | permission('auctions.manage') | none | list[Auction] | auctions | AUC; source `admin_auctions`; explicit validation/default 4xx/5xx | Partial: admin auction pages/actions | RSC/typed Route Handler under RLS | V,A,R,T |
| 22 | POST | `/api/admin/auctions` | permission('auctions.manage') | body:AuctionCreate=required | Auction / 201 | artworks, auctions | AUC; source `create_auction`; explicit 400, 404, 409 | Partial: admin auction pages/actions | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 23 | POST | `/api/admin/auctions/{id}/action` | permission('auctions.manage') | id:str=required; body:AuctionAdminAction=required | Auction | artworks, auctions, users | AUC; source `auction_action`; explicit 400, 404 | Partial: admin auction pages/actions | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 24 | GET | `/api/admin/bidders` | permission('bidders.manage') | none | list[BidderProfile] | bidders | AUC; source `list_bidders`; explicit validation/default 4xx/5xx | Partial: admin auction pages/actions | RSC/typed Route Handler under RLS | V,A,R,T |
| 25 | PATCH | `/api/admin/bidders/{user_id}` | permission('bidders.manage') | user_id:str=required; body:StatusIn=required | BidderProfile | bidders | AUC; source `set_bidder`; explicit 400, 404 | Partial: admin auction pages/actions | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 26 | GET | `/api/auctions` | public | none | list[Auction] | artworks, auctions, users | AUC; source `list_auctions`; explicit validation/default 4xx/5xx | Partial: auctions library + bid/watch routes | RSC read or cacheable Route Handler | V,P,T |
| 27 | GET | `/api/auctions/{id}` | optional | id:str=required; request:Request=required | Auction | artworks, auctions, users | AUC; source `get_auction`; explicit 404 | Partial: auctions library + bid/watch routes | RSC/typed Route Handler under RLS | V,P,A,T |
| 28 | POST | `/api/auctions/{id}/bids` | authenticated | id:str=required; body:BidCreate=required | Auction | artworks, auctions, bidders, users | AUC; source `place_bid`; explicit 400, 403, 404, 409 | Partial: auctions library + bid/watch routes | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 29 | POST | `/api/auctions/{id}/watch` | authenticated | id:str=required | implicit JSON | artworks, auctions, users | AUC; source `toggle_watch`; explicit 404 | Partial: auctions library + bid/watch routes | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 30 | GET | `/api/bidder` | authenticated | none | Optional[BidderProfile] | bidders | AUC; source `my_bidder`; explicit validation/default 4xx/5xx | Partial: auctions library + bid/watch routes | RSC/typed Route Handler under RLS | V,A,R,T |
| 31 | POST | `/api/bidder` | authenticated | body:BidderRegister=required | BidderProfile / 201 | bidders, counters, legal_acceptances | AUC; source `register_bidder`; explicit 400 | Partial: auctions library + bid/watch routes | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 32 | GET | `/api/me/watchlist` | authenticated | none | list[str] | users | AUC; source `my_watchlist`; explicit validation/default 4xx/5xx | Partial: auctions library + bid/watch routes | RSC/typed Route Handler under RLS | V,A,R,T |

## certdocs

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 33 | GET | `/api/admin/cert-docs` | permission('certificates.manage') | status:str='' | list[CertDoc] | cert_docs | CERT; source `admin_list`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 34 | POST | `/api/admin/cert-docs/{id}/action` | permission('certificates.manage') | id:str=required; body:CertAction=required | CertDoc | artists, cert_docs | CERT; source `review`; explicit 400, 403, 404, 409 | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 35 | POST | `/api/cert-docs` | authenticated | type:str=Form(...); issuer_name:str=Form(..., min_length=2); issue_date:str=Form(...); artwork_id:str=Form(''); artist_id:str=Form(''); issuer_org:str=Form(''); expiry_date:str=Form(''); certificate_number:str=Form(''); file:UploadFile=File(...) | CertDoc / 201 | artists, artworks, cert_docs, intermediaries, orders, representations, requests | CERT; source `upload`; explicit 400, 403, 404 | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 36 | GET | `/api/cert-docs/mine` | authenticated | none | list[CertDoc] | artists, cert_docs, intermediaries, orders, representations | CERT; source `mine`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 37 | GET | `/api/cert-docs/{id}/file` | authenticated | id:str=required; version:Optional[int]=None | implicit JSON | artists, cert_docs, intermediaries, representations | CERT; source `file_url`; explicit 404 | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 38 | POST | `/api/cert-docs/{id}/versions` | authenticated | id:str=required; note:str=Form(''); file:UploadFile=File(...) | CertDoc | cert_docs | CERT; source `new_version`; explicit 404, 409 | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 39 | GET | `/api/verify-certificate` | public | q:str=required | PublicCert | artworks, cert_docs, certificates | CERT; source `public_verify`; explicit 400, 404 | None | RSC read or cacheable Route Handler | V,P,X |

## commerce

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 40 | GET | `/api/account` | authenticated | none | AccountSummary | artworks, bidders, certificates, offers, orders, requests, users | COM; source `account`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 41 | GET | `/api/admin/offers` | permission('offers.manage') | none | list[Offer] | offers | COM; source `admin_offers`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 42 | GET | `/api/admin/orders` | permission('orders.manage') | none | list[Order] | orders | COM; source `admin_orders`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 43 | POST | `/api/admin/orders/{id}/action` | permission('orders.manage') | id:str=required; body:OrderAction=required | Order | artworks, ledger, orders | COM; source `order_action`; explicit 400, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 44 | GET | `/api/cart` | authenticated | none | CartView | artworks, users | COM; source `get_cart`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 45 | DELETE | `/api/cart/{artwork_id}` | authenticated | artwork_id:str=required | CartView | artworks, users | COM; source `remove_from_cart`; explicit validation/default 4xx/5xx | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 46 | POST | `/api/cart/{artwork_id}` | authenticated | artwork_id:str=required | CartView | artworks, users | COM; source `add_to_cart`; explicit 403, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 47 | POST | `/api/checkout` | authenticated | body:CheckoutIn=required | Order / 201 | artworks, orders, representations, users | COM; source `checkout`; explicit 400, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 48 | GET | `/api/intermediary/offers` | authenticated | none | list[Offer] | offers | COM; source `intermediary_offers`; explicit validation/default 4xx/5xx | Partial: intermediary page/actions | RSC/typed Route Handler under RLS | V,A,R,T |
| 49 | GET | `/api/me/wishlist` | authenticated | none | list[str] | users | COM; source `get_wishlist`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 50 | POST | `/api/me/wishlist/{artwork_id}` | authenticated | artwork_id:str=required; request:Request=required | implicit JSON | artworks, users | COM; source `toggle_wishlist`; explicit 404 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 51 | GET | `/api/notifications` | authenticated | none | list[Notification] | notifications | COM; source `notifications`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 52 | POST | `/api/notifications/read` | authenticated | body:IdList=required | implicit JSON | notifications | COM; source `mark_read`; explicit validation/default 4xx/5xx | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 53 | POST | `/api/offers` | authenticated | body:OfferCreate=required | Offer / 201 | artworks, offers | COM; source `make_offer`; explicit 403, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 54 | GET | `/api/offers/mine` | authenticated | none | list[Offer] | offers | COM; source `my_offers`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 55 | POST | `/api/offers/{id}/action` | authenticated | id:str=required; body:OfferAction=required | Offer | artists, artworks, offers, orders, representations, users | COM; source `offer_action`; explicit 400, 403, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 56 | GET | `/api/orders` | authenticated | none | list[Order] | orders | COM; source `my_orders`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 57 | POST | `/api/orders/{id}/shipping` | authenticated | id:str=required; body:ShippingIn=required | Order | artists, orders | COM; source `update_shipping`; explicit 400, 403, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 58 | GET | `/api/shipping` | authenticated | none | list[Order] | artists, orders | COM; source `my_shipping`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 59 | GET | `/api/studio/offers` | authenticated | none | list[Offer] | artists, offers | COM; source `artist_offers`; explicit validation/default 4xx/5xx | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,T |

## commissions

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 60 | GET | `/api/admin/commissions` | permission('requests.manage') | none | implicit JSON | commissions | COMM; source `all_commissions`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 61 | POST | `/api/admin/commissions` | permission('requests.manage') | body:StartIn=required | implicit JSON / 201 | artists, commissions, requests, users | COMM; source `start`; explicit 400, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 62 | GET | `/api/commissions` | authenticated | none | implicit JSON | artists, commissions | COMM; source `mine`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 63 | POST | `/api/commissions/{id}/action` | authenticated | id:str=required; body:ActionIn=required | implicit JSON | artists, commissions, ledger | COMM; source `action`; explicit 400, 403, 404, 409 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 64 | POST | `/api/commissions/{id}/pay` | authenticated | id:str=required | implicit JSON | commissions | COMM; source `pay`; explicit 400 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 65 | POST | `/api/commissions/{id}/quote` | authenticated | id:str=required; body:QuoteIn=required | implicit JSON | artists, commissions | COMM; source `quote`; explicit 400, 404 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |

## cron

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 66 | POST | `/api/cron/{job}` | public | job:str=required; request:Request=required; authorization:str=Header(''); x_webhook_id:str=Header('') | implicit JSON / 202 | cron_runs | CRON; source `cron_job`; explicit 400, 401, 404 | None | CF Cron/Queue -> idempotent RPC | V,P,I,C |

## discovery

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 67 | GET | `/api/admin/analytics` | permission('reports.view') | days:int=Query(30, ge=1, le=365) | AnalyticsReport | analytics_events, artists, artworks, auctions, commissions, enquiries, ledger, offers, orders | DISC; source `analytics`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 68 | GET | `/api/admin/artwork-taxonomy` | permission('artworks.review') | q:str=''; verified:Optional[bool]=None | list[ArtworkTaxonomyRow] | artworks | DISC; source `artwork_taxonomy`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 69 | PUT | `/api/admin/artworks/{id}/taxonomy` | permission('artworks.review') | id:str=required; body:ArtworkTaxonomyIn=required | ArtworkTaxonomyRow | artworks, taxonomy_terms | DISC; source `set_artwork_taxonomy`; explicit 400, 404 | Partial: marketplace review page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 70 | PUT | `/api/admin/discovery-settings` | permission('content.manage') | body:DiscoverySettings=required | DiscoverySettings | platform_settings | DISC; source `put_discovery_settings`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 71 | GET | `/api/admin/featured-artists` | permission('content.manage') | none | list[FeaturedSlot] | featured_slots | DISC; source `list_slots`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 72 | POST | `/api/admin/featured-artists` | permission('content.manage') | body:FeaturedSlotIn=required | FeaturedSlot / 201 | artists, featured_slots | DISC; source `create_slot`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 73 | DELETE | `/api/admin/featured-artists/{id}` | permission('content.manage') | id:str=required | implicit JSON / 204 | featured_slots | DISC; source `remove_slot`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 74 | GET | `/api/admin/homepage` | permission('content.manage') | none | HomepageConfig | platform_settings | DISC; source `get_home_draft`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 75 | PUT | `/api/admin/homepage` | permission('content.manage') | body:HomepageConfig=required | HomepageConfig | platform_settings | DISC; source `save_home_draft`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 76 | GET | `/api/admin/homepage/preview` | permission('content.manage') | none | HomepageConfig | platform_settings | DISC; source `preview_home`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 77 | POST | `/api/admin/homepage/publish` | permission('content.manage') | none | HomepageConfig | platform_settings | DISC; source `publish_home`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 78 | GET | `/api/admin/taxonomy` | permission('content.manage') | kind:str=Query(pattern='^(category\|artform\|style\|subject\|collection\|colour)$') | list[TaxonomyTerm] | artists, artworks, auctions, taxonomy_terms | DISC; source `admin_terms`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 79 | POST | `/api/admin/taxonomy` | permission('content.manage') | body:TaxonomyIn=required | TaxonomyTerm / 201 | artists, artworks, auctions, taxonomy_terms | DISC; source `create_term`; explicit 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 80 | PUT | `/api/admin/taxonomy/{id}` | permission('content.manage') | id:str=required; body:TaxonomyIn=required | TaxonomyTerm | artists, artworks, auctions, taxonomy_terms | DISC; source `update_term`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 81 | GET | `/api/admin/testimonials` | permission('content.manage') | status:str='' | list[Testimonial] | testimonials | DISC; source `admin_testimonials`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 82 | POST | `/api/admin/testimonials` | permission('content.manage') | body:TestimonialIn=required | Testimonial / 201 | artworks, testimonials | DISC; source `staff_testimonial`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 83 | PUT | `/api/admin/testimonials/{id}` | permission('content.manage') | id:str=required; body:TestimonialIn=required | Testimonial | testimonials | DISC; source `edit_testimonial`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 84 | POST | `/api/admin/testimonials/{id}/action` | permission('content.manage') | id:str=required; body:TestimonialAction=required | Testimonial | testimonials | DISC; source `testimonial_action`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 85 | GET | `/api/admin/whatsapp` | permission('settings.manage') | none | WhatsAppSettings | platform_settings | DISC; source `get_whatsapp`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 86 | PUT | `/api/admin/whatsapp` | permission('settings.manage') | body:WhatsAppSettings=required | WhatsAppSettings | platform_settings | DISC; source `put_whatsapp`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 87 | GET | `/api/artists/{id}/page` | public | id:str=required; request:Request=required | ArtistPublicPage | articles, artists, artworks, featured_slots, users | DISC; source `artist_page`; explicit 404 | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 88 | GET | `/api/discover/artists` | optional | tab:str=Query('all', pattern='^(week\|featured\|popular\|trending\|visited\|all)$'); period:Optional[int]=Query(None); q:str=''; location:str=''; artform:str=''; style:str=''; medium:str=''; sort:str=Query('name', pattern='^(name\|newest\|popular\|recent)$'); page:int=Query(1, ge=1); per:int=Query(12, ge=1, le=48); include_test:bool=False | ArtistDiscoveryPage | analytics_events, artists, artworks, enquiries, featured_slots, orders, platform_settings, users | DISC; source `discover_artists`; explicit 403 | None | RSC/typed Route Handler under RLS | V,P,A |
| 89 | GET | `/api/discover/facets` | public | none | DirectoryFacets | artists, artworks, taxonomy_terms, users | DISC; source `directory_facets`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 90 | GET | `/api/discover/settings` | public | none | DiscoverySettings | platform_settings | DISC; source `get_discovery_settings`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 91 | GET | `/api/homepage` | public | none | HomepageConfig | platform_settings | DISC; source `homepage`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 92 | GET | `/api/support/whatsapp` | public | none | WhatsAppSettings | platform_settings | DISC; source `whatsapp_public`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 93 | GET | `/api/taxonomy` | public | kind:str=Query(pattern='^(category\|artform\|style\|subject\|collection\|colour)$'); counts:bool=True | list[TaxonomyTerm] | artists, artworks, auctions, taxonomy_terms | DISC; source `list_terms`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 94 | GET | `/api/taxonomy/{kind}/{slug}` | public | kind:str=required; slug:str=required | TaxonomyTerm | artists, artworks, auctions, taxonomy_terms | DISC; source `get_term`; explicit 404 | None | RSC read or cacheable Route Handler | V,P |
| 95 | GET | `/api/testimonials` | public | limit:int=Query(6, ge=1, le=24) | list[Testimonial] | testimonials | DISC; source `public_testimonials`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 96 | POST | `/api/testimonials` | authenticated | body:TestimonialIn=required | Testimonial / 201 | artworks, orders, testimonials | DISC; source `submit_testimonial`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 97 | POST | `/api/track` | public | body:TrackIn=required; request:Request=required | implicit JSON / 204 | none/direct helper | DISC; source `track_event`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,P,I |

## intermediary

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 98 | GET | `/api/admin/intermediaries` | permission('intermediaries.review') | none | list[Intermediary] | intermediaries | REP; source `admin_list`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 99 | PATCH | `/api/admin/intermediaries/{id}` | permission('intermediaries.review') | id:str=required; body:StatusIn=required | Intermediary | intermediaries | REP; source `review`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 100 | GET | `/api/admin/representations` | permission('intermediaries.review') | none | list[Representation] | representations | REP; source `admin_reps`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 101 | POST | `/api/admin/representations/{id}/terminate` | permission('intermediaries.review') | id:str=required; body:StatusIn=required | Representation | intermediaries, representations | REP; source `admin_terminate`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 102 | GET | `/api/intermediary` | authenticated | none | IntermediaryDashboard | artworks, enquiries, intermediaries, orders, representations | REP; source `dashboard`; explicit validation/default 4xx/5xx | Partial: intermediary page/actions | RSC/typed Route Handler under RLS | V,A,R,X |
| 103 | POST | `/api/intermediary/artworks/{artist_id}` | authenticated | artist_id:str=required; body:ArtworkSubmit=required | Artwork / 201 | artists, intermediaries, representations | REP; source `submit_for_artist`; explicit 403 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 104 | PUT | `/api/intermediary/artworks/{id}/draft` | authenticated | id:str=required; body:ArtworkSubmit=required | Artwork | artworks, intermediaries, representations | REP; source `edit_artist_draft`; explicit 403, 404 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 105 | POST | `/api/intermediary/invites` | authenticated | body:InviteV2=required | Representation / 201 | artists, artworks, intermediaries, representations | REP; source `invite`; explicit 400, 403, 404, 409 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 106 | POST | `/api/intermediary/register` | authenticated | body:IntermediaryRegister=required | Intermediary / 201 | intermediaries, legal_acceptances | REP; source `register`; explicit 400 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 107 | POST | `/api/representations/{id}/action` | authenticated | id:str=required; body:RepresentationAction=required | Representation | artists, intermediaries, representations | REP; source `rep_action`; explicit 403, 404, 409 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 108 | PUT | `/api/representations/{id}/scopes` | authenticated | id:str=required; body:ScopeUpdate=required | Representation | artists, intermediaries, representations | REP; source `update_scopes`; explicit 400, 403 | Partial: intermediary page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 109 | GET | `/api/studio/representations` | authenticated | none | list[Representation] | artists, representations | REP; source `artist_reps`; explicit validation/default 4xx/5xx | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,X |

## journal

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 110 | GET | `/api/admin/journal` | permission('content.manage') | status:str=''; category:str='' | list[ArticleV2] | articles | JRN; source `admin_list`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 111 | POST | `/api/admin/journal` | permission('content.manage') | body:ArticleV2In=required | ArticleV2 / 201 | articles | JRN; source `create`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 112 | POST | `/api/admin/journal-authors` | permission('content.manage') | body:Author=required | Author | journal_authors | JRN; source `save_author`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 113 | PUT | `/api/admin/journal-categories` | permission('content.manage') | body:list[str]=required | implicit JSON | none/direct helper | JRN; source `set_categories`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 114 | POST | `/api/admin/journal-tags/rename` | permission('content.manage') | body:dict[str, str]=required | implicit JSON | articles | JRN; source `rename_tag`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 115 | GET | `/api/admin/journal-taxonomy` | permission('content.manage') | none | implicit JSON | articles, journal_authors | JRN; source `taxonomy`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 116 | PUT | `/api/admin/journal/{id}` | permission('content.manage') | id:str=required; body:ArticleV2In=required | ArticleV2 | articles | JRN; source `update`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 117 | POST | `/api/admin/journal/{id}/action` | permission('content.manage') | id:str=required; body:ArticleAction=required | ArticleV2 | articles, artists | JRN; source `act`; explicit 400, 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 118 | GET | `/api/journal` | public | q:str=''; category:str=''; tag:str=''; page:int=1 | JournalPage | articles | JRN; source `journal`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P,X |
| 119 | GET | `/api/journal/{slug}` | public | slug:str=required; request:Request=required | ArticleView | articles, artists, artworks, journal_bookmarks | JRN; source `article`; explicit 404 | None | RSC read or cacheable Route Handler | V,P,X |
| 120 | GET | `/api/me/journal-bookmarks` | authenticated | none | list[ArticleCard] | articles, journal_bookmarks | JRN; source `bookmarks`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 121 | DELETE | `/api/me/journal-bookmarks/{slug}` | authenticated | slug:str=required | implicit JSON | journal_bookmarks | JRN; source `del_bookmark`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 122 | POST | `/api/me/journal-bookmarks/{slug}` | authenticated | slug:str=required | implicit JSON | articles, journal_bookmarks | JRN; source `add_bookmark`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 123 | GET | `/api/studio/stories` | authenticated | none | list[ArticleV2] | articles, artists | JRN; source `my_stories`; explicit validation/default 4xx/5xx | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,X |
| 124 | POST | `/api/studio/stories` | authenticated | body:StoryIn=required | ArticleV2 / 201 | articles, artists, intermediaries, representations | JRN; source `submit_story`; explicit 403 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 125 | POST | `/api/studio/stories/{id}/quote-approval` | authenticated | id:str=required; body:QuoteApproval=required | ArticleV2 | articles, artists | JRN; source `approve_quotes`; explicit 404 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |

## legal

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 126 | GET | `/api/admin/legal` | permission('legal.draft') | none | list[LegalDoc] | legal_docs | LEGAL; source `admin_index`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 127 | POST | `/api/admin/legal` | permission('legal.draft') | body:LegalCreate=required | LegalDocDetail / 201 | legal_docs, legal_versions | LEGAL; source `create`; explicit 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 128 | GET | `/api/admin/legal-acceptances` | permission('legal.draft') | key:str='' | list[Acceptance] | legal_acceptances | LEGAL; source `all_acceptances`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 129 | GET | `/api/admin/legal/{key}` | permission('legal.draft') | key:str=required | LegalDocDetail | legal_docs, legal_versions | LEGAL; source `admin_get`; explicit 404 | None | RSC/typed Route Handler under RLS | V,A,R |
| 130 | PUT | `/api/admin/legal/{key}` | permission('legal.draft') | key:str=required; body:LegalEdit=required | LegalDocDetail | legal_docs, legal_versions | LEGAL; source `save_draft`; explicit 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 131 | POST | `/api/admin/legal/{key}/action` | permission('legal.draft') | key:str=required; body:LegalAction=required | LegalDocDetail | legal_docs, legal_versions | LEGAL; source `action`; explicit 400, 403, 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 132 | GET | `/api/legal-docs` | public | none | list[PublicLegal] | legal_docs, legal_versions | LEGAL; source `public_index`; explicit 404 | Partial: legal tables/artist acceptance | RSC read or cacheable Route Handler | V,P |
| 133 | GET | `/api/legal-docs/{key}` | public | key:str=required | PublicLegal | legal_docs, legal_versions | LEGAL; source `public_doc`; explicit 404 | Partial: legal tables/artist acceptance | RSC read or cacheable Route Handler | V,P |
| 134 | POST | `/api/legal-docs/{key}/accept` | authenticated | key:str=required; body:AcceptIn=required | Acceptance / 201 | legal_acceptances, legal_docs, legal_versions | LEGAL; source `accept`; explicit 404 | Partial: legal tables/artist acceptance | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 135 | GET | `/api/me/acceptances` | authenticated | none | list[Acceptance] | legal_acceptances | LEGAL; source `my_acceptances`; explicit validation/default 4xx/5xx | Partial: legal tables/artist acceptance | RSC/typed Route Handler under RLS | V,A,R |
| 136 | GET | `/api/me/agreements` | authenticated | none | list[AgreementStatus] | artists, intermediaries, legal_acceptances, legal_docs | LEGAL; source `my_agreements`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |

## media

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 137 | GET | `/api/admin/media` | permission('artworks.review') | none | implicit JSON | media | MEDIA; source `media_queue`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 138 | PATCH | `/api/admin/media/{id}` | permission('artworks.review') | id:str=required; body:dict=required | implicit JSON | artworks, media | MEDIA; source `review_media`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 139 | GET | `/api/uploads/config` | public | none | implicit JSON | none/direct helper | MEDIA; source `upload_config`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |
| 140 | POST | `/api/uploads/register` | authenticated | body:RegisterIn=required | implicit JSON | media | MEDIA; source `register`; explicit 400, 403, 503 | None | Server Action/Route Handler + private storage policy | V,A,R,I |
| 141 | POST | `/api/uploads/sign` | authenticated | body:SignIn=required | implicit JSON | none/direct helper | MEDIA; source `sign`; explicit 403, 503 | None | Server Action/Route Handler + private storage policy | V,A,R,I |
| 142 | DELETE | `/api/uploads/{id}` | authenticated | id:str=required | implicit JSON | artworks, media | MEDIA; source `delete`; explicit 404, 409 | None | Server Action/Route Handler + private storage policy | V,A,R,I |
| 143 | GET | `/api/uploads/{id}/original` | authenticated | id:str=required | implicit JSON | media | MEDIA; source `original`; explicit 404 | None | RSC/typed Route Handler under RLS | V,A,R |

## payments

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 144 | GET | `/api/admin/payments` | permission('orders.manage') | none | implicit JSON | payments | PAY; source `all_payments`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 145 | GET | `/api/payments/config` | public | none | implicit JSON | none/direct helper | PAY; source `payments_config`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P,T |
| 146 | GET | `/api/payments/mine` | authenticated | none | implicit JSON | payments | PAY; source `my_payments`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,T |
| 147 | POST | `/api/payments/orders/{order_id}` | authenticated | order_id:str=required | implicit JSON | orders, payments | PAY; source `pay_order`; explicit 400, 404, 503 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 148 | POST | `/api/payments/verify` | authenticated | body:VerifyIn=required | implicit JSON | payments | PAY; source `verify`; explicit 400, 402, 404 | None | Zod Route Handler/Action + transactional RPC | V,A,R,I,T |
| 149 | POST | `/api/payments/webhook` | public | request:Request=required | implicit JSON | payment_events, payments | PAY; source `webhook`; explicit 400 | None | Signed idempotent Route Handler + RPC | V,P,I,T,W |

## people

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 150 | GET | `/api/admin/people` | permission('users.view') | q:str=''; role:str=''; status:str=''; staff_only:bool=False; page:int=1 | PeoplePage | artists, invites, users | IDENT; source `people`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 151 | POST | `/api/admin/people` | permission('users.manage') | body:PersonCreate=required | Person / 201 | artists, intermediaries, invites, users | IDENT; source `create_person`; explicit 400, 403, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 152 | POST | `/api/admin/people/invites/{invite_id}/revoke` | permission('users.manage') | invite_id:str=required | implicit JSON | invites | IDENT; source `revoke_invite`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 153 | PATCH | `/api/admin/people/{user_id}` | permission('users.manage') | user_id:str=required; body:PersonUpdate=required | Person | artists, users | IDENT; source `update_person`; explicit 400, 403, 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 154 | GET | `/api/admin/people/{user_id}/history` | permission('users.view') | user_id:str=required | implicit JSON | audit_logs, deactivation_requests, users | IDENT; source `person_history`; explicit 404 | None | RSC/typed Route Handler under RLS | V,A,R |
| 155 | POST | `/api/admin/people/{user_id}/recover` | permission('users.manage') | user_id:str=required | implicit JSON | users | IDENT; source `recover_access`; explicit 403, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 156 | GET | `/api/me/sessions` | authenticated | none | list[SessionRow] | none/direct helper | IDENT; source `my_sessions`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 157 | POST | `/api/me/sessions/{sid}/revoke` | authenticated | sid:str=required | implicit JSON | none/direct helper | IDENT; source `revoke_my_session`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |

## profiles

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 158 | GET | `/api/admin/artist-fields` | permission('artists.review') | none | implicit JSON | none/direct helper | PROFILE; source `get_fields`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 159 | PUT | `/api/admin/artist-fields` | permission('settings.manage') | body:dict[str, Literal['required', 'optional', 'hidden']]=required | implicit JSON | none/direct helper | PROFILE; source `put_fields`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 160 | GET | `/api/admin/artists/{id}/profile` | permission('artists.review') | id:str=required | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `admin_artist_profile`; explicit 404 | Partial: marketplace review page/actions | RSC/typed Route Handler under RLS | V,A,R,X |
| 161 | POST | `/api/admin/artists/{id}/verify` | permission('artists.review') | id:str=required; body:VerifyIn=required | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `verify_artist`; explicit 403, 404 | Partial: marketplace review page/actions | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 162 | POST | `/api/files` | authenticated | kind:Literal['portfolio_image', 'journal_image', 'video', 'document']=Form(...); file:UploadFile=File(...) | implicit JSON | files | PROFILE; source `upload_file`; explicit 403 | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 163 | DELETE | `/api/me/avatar` | authenticated | none | Profile | deactivation_requests, users | PROFILE; source `remove_avatar`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 164 | POST | `/api/me/avatar` | authenticated | file:UploadFile=File(...); x:int=Form(0); y:int=Form(0); size:int=Form(0) | Profile | deactivation_requests, users | PROFILE; source `upload_avatar`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 165 | DELETE | `/api/me/deactivation` | authenticated | none | implicit JSON | deactivation_requests | PROFILE; source `cancel_deactivation`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 166 | POST | `/api/me/deactivation` | authenticated | body:DeactivationIn=required | implicit JSON / 201 | deactivation_requests | PROFILE; source `request_deactivation`; explicit 409 | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 167 | GET | `/api/me/prefs` | authenticated | none | Prefs | newsletter, users | PROFILE; source `get_prefs`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 168 | PUT | `/api/me/prefs` | authenticated | body:Prefs=required | Prefs | newsletter, users | PROFILE; source `put_prefs`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 169 | GET | `/api/me/profile` | authenticated | none | Profile | deactivation_requests, users | PROFILE; source `get_profile`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 170 | PUT | `/api/me/profile` | authenticated | body:ProfileIn=required | Profile | deactivation_requests, users | PROFILE; source `put_profile`; explicit validation/default 4xx/5xx | None | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 171 | PUT | `/api/studio/finance` | authenticated | body:FinanceIn=required | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `put_finance`; explicit 404 | Partial: artist page/actions | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 172 | POST | `/api/studio/identity` | authenticated | file:UploadFile=File(...) | ArtistProfileView | artist_finance, artists, identity_docs, legal_acceptances | PROFILE; source `submit_identity`; explicit 404 | Partial: artist page/actions | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 173 | PUT | `/api/studio/participation` | authenticated | body:ParticipationIn=required | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `set_participation`; explicit 404 | Partial: artist page/actions | Server Action/Route Handler + private storage policy | V,A,R,I,X |
| 174 | GET | `/api/studio/profile` | authenticated | none | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `get_artist_profile`; explicit 404 | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,X |
| 175 | PUT | `/api/studio/profile` | authenticated | body:ArtistProfileExt=required | ArtistProfileView | artist_finance, artists, legal_acceptances | PROFILE; source `put_artist_profile`; explicit 404 | Partial: artist page/actions | Server Action/Route Handler + private storage policy | V,A,R,I,X |

## public

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 176 | GET | `/api/artists` | public | none | list[Artist] | artists | PUBLIC; source `list_artists`; explicit validation/default 4xx/5xx | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 177 | GET | `/api/artists/{id}` | public | id:str=required | Artist | artists | PUBLIC; source `get_artist`; explicit 404 | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 178 | GET | `/api/artworks` | public | request:Request=required; sort:str='featured' | list[Artwork] | artworks | PUBLIC; source `list_artworks`; explicit validation/default 4xx/5xx | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 179 | GET | `/api/artworks/{id}` | public | id:str=required; request:Request=required | ArtworkDetail | artists, artworks | PUBLIC; source `get_artwork`; explicit 404 | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 180 | POST | `/api/enquiries` | public | body:EnquiryCreate=required; request:Request=required | Enquiry / 201 | artworks, enquiries | PUBLIC; source `create_enquiry`; explicit 404 | Equivalent: contact server action/RPC | Zod Server Action/Route Handler + RLS/RPC | V,P,I |
| 181 | GET | `/api/meta/filters` | public | none | FilterMeta | artworks | PUBLIC; source `filters`; explicit validation/default 4xx/5xx | Partial: server-side catalogue | RSC read or cacheable Route Handler | V,P |
| 182 | GET | `/api/search` | public | q:str=Query(min_length=2) | implicit JSON | articles, artists, artworks, auctions | PUBLIC; source `search`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |

## server

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 183 | GET | `/api/` | public | none | implicit JSON | none/direct helper | PUBLIC; source `root`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |

## services

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 184 | GET | `/api/admin/audit` | permission('audit.view') | entity:Optional[str]=None | list[AuditEntry] | audit_logs | SERVICE; source `audit_log`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 185 | GET | `/api/admin/certificates` | permission('certificates.manage') | none | list[Certificate] | certificates | SERVICE; source `admin_certs`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 186 | POST | `/api/admin/certificates` | permission('certificates.manage') | body:CertificateIn=required | Certificate / 201 | artworks, certificates, orders | SERVICE; source `issue_cert`; explicit 404, 409 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 187 | PATCH | `/api/admin/certificates/{id}` | permission('certificates.manage') | id:str=required; body:StatusIn=required | Certificate | certificates | SERVICE; source `revoke_cert`; explicit 400, 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 188 | GET | `/api/admin/email-log` | permission('audit.view') | none | implicit JSON | email_log | SERVICE; source `email_log`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 189 | GET | `/api/admin/email-stats` | permission('audit.view') | none | implicit JSON | cron_runs, email_log | SERVICE; source `email_stats`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 190 | POST | `/api/admin/email/retry` | permission('settings.manage') | none | implicit JSON | email_log | SERVICE; source `email_retry_now`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 191 | GET | `/api/admin/integrations` | permission('settings.manage') | none | implicit JSON | email_log | SERVICE; source `integrations`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 192 | POST | `/api/admin/newsletter/send` | permission('content.manage') | body:dict[str, str]=required | implicit JSON | articles, newsletter | SERVICE; source `send_newsletter`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 193 | GET | `/api/admin/reports` | permission('reports.view') | none | Reports | artists, artworks, auctions, bidders, certificates, enquiries, newsletter, offers, orders, requests, users | SERVICE; source `reports`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 194 | GET | `/api/admin/requests` | permission('requests.manage') | type:Optional[str]=None | list[ServiceRequest] | requests | SERVICE; source `admin_requests`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 195 | PATCH | `/api/admin/requests/{id}` | permission('requests.manage') | id:str=required; body:RequestUpdate=required | ServiceRequest | requests | SERVICE; source `update_request`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 196 | GET | `/api/admin/settings` | permission('settings.manage') | none | PlatformSettings | none/direct helper | SERVICE; source `get_platform_settings`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 197 | PUT | `/api/admin/settings` | permission('settings.manage') | body:PlatformSettings=required; request:Request=required | PlatformSettings | none/direct helper | SERVICE; source `put_settings`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 198 | GET | `/api/certificates/{number}` | public | number:str=required | Certificate | certificates | SERVICE; source `verify_certificate`; explicit 404 | None | RSC read or cacheable Route Handler | V,P |
| 199 | GET | `/api/legal` | public | none | implicit JSON | none/direct helper | SERVICE; source `legal_index`; explicit validation/default 4xx/5xx | Partial: legal tables/artist acceptance | RSC read or cacheable Route Handler | V,P |
| 200 | GET | `/api/me/email-prefs` | authenticated | none | implicit JSON | users | SERVICE; source `get_prefs`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R |
| 201 | PUT | `/api/me/email-prefs` | authenticated | body:dict[str, bool]=required | implicit JSON | users | SERVICE; source `put_prefs`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I |
| 202 | POST | `/api/newsletter` | public | body:NewsletterIn=required | NewsletterOut | newsletter | SERVICE; source `subscribe`; explicit 400 | None | Zod Server Action/Route Handler + RLS/RPC | V,P,I |
| 203 | POST | `/api/newsletter/unsubscribe` | public | body:NewsletterIn=required | NewsletterOut | newsletter | SERVICE; source `unsubscribe`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,P,I |
| 204 | POST | `/api/newsletter/unsubscribe-token/{token}` | public | token:str=required | NewsletterOut | newsletter | SERVICE; source `unsubscribe_token`; explicit 404 | None | Zod Server Action/Route Handler + RLS/RPC | V,P,I |
| 205 | POST | `/api/requests` | optional | body:RequestCreate=required | ServiceRequest / 201 | requests | SERVICE; source `create_request`; explicit validation/default 4xx/5xx | None | Zod Server Action/Route Handler + RLS/RPC | V,P,A,I |
| 206 | GET | `/api/settings/public` | public | none | PublicSettings | none/direct helper | SERVICE; source `public_settings`; explicit validation/default 4xx/5xx | Partial: platform_settings | RSC read or cacheable Route Handler | V,P |
| 207 | GET | `/api/sitemap.xml` | public | none | implicit JSON | articles, artists, artworks, auctions | SERVICE; source `sitemap`; explicit validation/default 4xx/5xx | None | RSC read or cacheable Route Handler | V,P |

## studio

| # | Method | Route | Auth/role | Request schema | Response schema | DB dependencies | Rules/errors | Existing Next.js | Migration | Tests |
|---:|---|---|---|---|---|---|---|---|---|---|
| 208 | POST | `/api/artists/register` | authenticated | body:ArtistRegisterIn=required | Artist / 201 | artists, legal_acceptances | ARTIST; source `register_artist`; explicit 400 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 209 | GET | `/api/me` | authenticated | none | Me | artists, bidders, intermediaries, notifications | ARTIST; source `me`; explicit validation/default 4xx/5xx | None | RSC/typed Route Handler under RLS | V,A,R,X |
| 210 | GET | `/api/studio` | authenticated | none | Studio | artists, artworks, auctions, enquiries | ARTIST; source `studio`; explicit validation/default 4xx/5xx | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,X |
| 211 | POST | `/api/studio/artworks` | authenticated | body:ArtworkSubmit=required | Artwork / 201 | artists, artworks | ARTIST; source `submit_artwork`; explicit 400 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 212 | PATCH | `/api/studio/artworks/{id}` | authenticated | id:str=required; body:ArtworkEdit=required | Artwork | artists, artworks, media | ARTIST; source `edit_artwork`; explicit 400, 404, 409 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 213 | PUT | `/api/studio/artworks/{id}/draft` | authenticated | id:str=required; body:ArtworkSubmit=required | Artwork | artists, artworks | ARTIST; source `edit_draft`; explicit 400, 404, 409 | Partial: artist page/actions | Zod Server Action/Route Handler + RLS/RPC | V,A,R,I,X |
| 214 | GET | `/api/studio/sales` | authenticated | none | implicit JSON | artists, orders | ARTIST; source `studio_sales`; explicit validation/default 4xx/5xx | Partial: artist page/actions | RSC/typed Route Handler under RLS | V,A,R,X |

## Duplicate and obsolete surface

| Surface | Decision |
|---|---|
| Clerk config and proxy | Remove; Supabase Auth is authoritative. |
| `/api/users*` and `/api/admin/people*` | Consolidate into a permissioned people/access service; keep compatibility redirects only during migration. |
| `/api/certificates/{number}` and `/api/verify-certificate?q=` | One public verification contract backed by `certificates`; retain one alias temporarily. |
| Legacy admin certificates and `cert-docs` | Use existing `certificates` + `certificate_files`; port the richer review/version behaviour without duplicate tables. |
| `/api/legal` and `/api/legal-docs*` | `/api/legal` is obsolete; use versioned legal document contracts. |
| `/api/me/email-prefs` and `/api/me/prefs` | Consolidate into one preferences resource. |
| `/api/files` and `/api/uploads*` | Consolidate into one signed media service with purpose-specific policies. |
| Mongo polling/report endpoints | Reimplement as bounded SQL views/RPCs; do not reproduce unbounded collection scans. |

## Pydantic schema registry

Endpoint rows reference the source models below. TypeScript/Zod schemas must preserve required/optional status and bounds; generated database types do not replace runtime validation.

| Source | Model | Fields |
|---|---|---|
| `models/ai.py` | `DescriptionDraftIn` | title:str=Field(min_length=2, max_length=200); medium:str=''; style:str=''; subject:str=''; year:Optional[int]=None; width_cm:Optional[float]=None; height_cm:Optional[float]=None; framed:bool=False; notes:str=Field('', max_length=1500); current:str=Field('', max_length=4000); voice:Literal['artist', 'gallery']='artist' |
| `models/ai.py` | `JournalDraftIn` | topic:str=Field(min_length=5, max_length=300); notes:str=Field('', max_length=3000); category:str=''; length:Literal['short', 'medium', 'long']='medium'; related_artist_ids:list[str]=[]; related_artwork_ids:list[str]=[] |
| `models/ai.py` | `ArtworkQuestionIn` | session_id:str=Field(min_length=8, max_length=64, pattern='^[A-Za-z0-9-]+$'); question:str=Field(min_length=2, max_length=500) |
| `models/ai.py` | `ChatMessage` | role:Literal['collector', 'assistant']; text:str; at:datetime |
| `models/ai.py` | `ArtworkChat` | session_id:str; artwork_id:str; messages:list[ChatMessage]=[]; remaining:int |
| `models/ai.py` | `TaxonomySuggestion` | category:str=''; artforms:list[str]=[]; styles:list[str]=[]; subjects:list[str]=[]; colours:list[str]=[]; rationale:str='' |
| `models/ai.py` | `AiUsageItem` | id:str; kind:Literal['artwork_description', 'journal_draft', 'artwork_answer', 'taxonomy_suggestion']; who:str; signed_in:bool; target_title:str; target_link:str=''; prompt:str=''; preview:str=''; chars:int=0; model:str=''; at:datetime |
| `models/ai.py` | `AiUsagePage` | items:list[AiUsageItem]; total:int; page:int; pages:int; counts:dict[str, int] |
| `models/attribution.py` | `AffectedField` | json_path:str; original_value:str; placeholder:str |
| `models/attribution.py` | `AttributionDecision` | action:Literal['confirm', 'request_corrections', 'reject']; note:str; content_confirmed:bool=False; by_user_id:str; by_name:str; by_email:str; by_role:str; at:datetime |
| `models/attribution.py` | `AttributionReview` | id:str; collection:Literal['articles', 'artworks', 'platform_settings']; source_id:str; record_title:str; record_link:str=''; fields:list[AffectedField]; existing_status:str; record_history:list[dict]=[]; state:ReviewState='pending'; decisions:list[AttributionDecision]=[] |
| `models/attribution.py` | `AttributionDecisionIn` | action:Literal['confirm', 'request_corrections', 'reject']; note:str=Field(min_length=10, max_length=2000); content_confirmed:bool=False |
| `models/discovery.py` | `CollectionRule` | min_price:Optional[int]=Field(default=None, ge=0); max_price:Optional[int]=Field(default=None, ge=0); artforms:list[str]=[]; styles:list[str]=[]; subjects:list[str]=[]; new_days:Optional[int]=Field(default=None, ge=1, le=365); emerging_months:Optional[int]=Field(default=None, ge=1, le=60); featured:bool=False; auction:bool=False |
| `models/discovery.py` | `TaxonomyTerm` | id:str; kind:TaxKind; slug:str; name:str; description:str=''; image:str=''; order:int=0; active:bool=True; nav:Literal['main', 'more', 'hidden']='main'; rule:Optional[CollectionRule]=None; artwork_count:int=0; artist_count:int=0; preview_image:str=''; preview_verified:bool=False |
| `models/discovery.py` | `TaxonomyIn` | kind:TaxKind; name:str=Field(min_length=2, max_length=60); slug:str=Field(default='', pattern='^$\|^[a-z0-9]+(-[a-z0-9]+)*$', max_length=60); description:str=Field(default='', max_length=600); image:str=Field(default='', max_length=600); order:int=0; active:bool=True; nav:Literal['main', 'more', 'hidden']='main'; rule:Optional[CollectionRule]=None |
| `models/discovery.py` | `ArtworkTaxonomyIn` | category:str=''; artforms:list[str]=[]; styles:list[str]=[]; subjects:list[str]=[]; collections:list[str]=[]; colours:list[str]=[]; verified:bool=False; ai_assisted:bool=False |
| `models/discovery.py` | `ArtworkTaxonomyRow` | id:str; title:str; artist_name:str; image:str=''; status:str; category:str=''; artforms:list[str]=[]; styles:list[str]=[]; subjects:list[str]=[]; collections:list[str]=[]; colours:list[str]=[]; taxonomy_verified:bool=False; taxonomy_source:str='' |
| `models/discovery.py` | `ArtistCard` | id:str; name:str; location:str=''; city:str=''; country:str='India'; primary_artform:str=''; photo:str=''; preview_image:str=''; preview_artwork_id:str=''; artist_code:str=''; artwork_count:int=0; score:float=0; blurb:str=''; commissions_open:bool=False; is_demo:bool=False |
| `models/discovery.py` | `ArtistDiscoveryPage` | tab:ArtistTab; period:int; basis:str; items:list[ArtistCard]; total:int; page:int; pages:int |
| `models/discovery.py` | `DirectoryFacets` | locations:list[str]; artforms:list[str]; styles:list[str]; mediums:list[str] |
| `models/discovery.py` | `FeaturedSlot` | id:str; artist_id:str; artist_name:str=''; slot:Literal['week', 'featured']='week'; starts_at:datetime; ends_at:datetime; order:int=0; blurb:str=''; state:Literal['scheduled', 'active', 'expired']='scheduled'; created_by:str='' |
| `models/discovery.py` | `FeaturedSlotIn` | artist_id:str; slot:Literal['week', 'featured']='week'; starts_at:datetime; ends_at:datetime; order:int=0; blurb:str=Field(default='', max_length=500) |
| `models/discovery.py` | `DiscoverySettings` | weights:dict[str, float]={'artist_view': 1, 'artwork_view': 0.5, 'wishlist_add': 3, 'enquiry': 5, 'sale': 10}; trending_days:Literal[7, 30, 90]=7; popular_days:Literal[7, 30, 90, 365]=90; home_limit:int=Field(default=6, ge=3, le=12) |
| `models/discovery.py` | `HomeSection` | key:str; title:str=''; enabled:bool=True; limit:int=Field(default=6, ge=1, le=24) |
| `models/discovery.py` | `HomepageConfig` | sections:list[HomeSection]; published_at:Optional[datetime]=None; published_by:str=''; draft_differs:bool=False |
| `models/discovery.py` | `TestimonialIn` | display_name:str=Field(min_length=2, max_length=60); text:str=Field(min_length=20, max_length=800); rating:Optional[int]=Field(default=None, ge=1, le=5); photo:str=Field(default='', max_length=600); artwork_id:str=''; consent_display:bool=False; city:str=Field(default='', max_length=60) |
| `models/discovery.py` | `Testimonial` | id:str; display_name:str; text:str; rating:Optional[int]=None; photo:str=''; artwork_id:str=''; artwork_title:str=''; city:str=''; consent_display:bool=False; source:Literal['customer', 'staff_entry']='customer'; verified_purchase:bool=False; verified:bool=False; verification_note:str=''; status:Literal['submitted', 'approved', 'published', 'unpublished', 'rejected']='submitted'; created_at:datetime; published_at:Optional[datetime]=None |
| `models/discovery.py` | `TestimonialAction` | action:Literal['verify', 'approve', 'publish', 'unpublish', 'reject']; note:str=Field(default='', max_length=400) |
| `models/discovery.py` | `WhatsAppSettings` | enabled:bool=False; number:str=Field(default='', pattern='^$\|^[1-9][0-9]{9,14}$'); default_message:str=Field(default="Hello tRA, I'd like help with an artwork.", max_length=300); privacy_note:str=Field(default="Opens WhatsApp, a third-party service run by Meta. Your number and message are shared with WhatsApp and tRA's support team.", max_length=400) |
| `models/discovery.py` | `TrackIn` | type:Literal['featured_click']; ref:str=Field(min_length=1, max_length=80) |
| `models/discovery.py` | `AnalyticsRow` | ref:str; label:str=''; count:int |
| `models/discovery.py` | `AnalyticsReport` | days:int; totals:dict[str, int]; unique_visitors:int; top_artists:list[AnalyticsRow]; top_artworks:list[AnalyticsRow]; top_searches:list[AnalyticsRow]; top_subjects:list[AnalyticsRow]; top_categories:list[AnalyticsRow]; top_collections:list[AnalyticsRow]; featured_clicks:list[AnalyticsRow] |
| `models/discovery.py` | `ArtistPublicPage` | id:str; name:str; artist_code:str=''; photo:str=''; location:str=''; city:str=''; country:str='India'; since:int=2024; bio:str=''; statement:str=''; artforms:list[str]=[]; specialisation:str=''; education:str=''; exhibitions:str=''; awards:str=''; commissions_open:bool=False; available:list[dict]=[]; sold:list[dict]=[]; sold_disclosed:bool=False; stories:list[dict]=[]; featured_blurb:str=''; is_demo:bool=False |
| `models/gallery.py` | `Artist` | id:str=Field(default_factory=_id); name:str; location:str; bio:str; styles:list[str]=[]; portrait:str=''; email:str=''; phone:str=''; since:int=2024; status:ReviewStatus='pending'; user_id:Optional[str]=None; review_note:str=''; statement:str=''; education:str=''; exhibitions:str=''; awards:str=''; social:str=''; commissions_open:bool=False; artist_code:str=''; public_reference:str=''; participation:str='independent'; is_demo:bool=False; created_at:datetime=Field(default_factory=_now) |
| `models/gallery.py` | `ArtistRegister` | name:str=Field(min_length=2); location:str=Field(min_length=2); bio:str=Field(min_length=10); styles:list[str]=Field(min_length=1); phone:str='' |
| `models/gallery.py` | `Artwork` | id:str=Field(default_factory=_id); title:str; artist_id:str; artist_name:str; style:str; medium:str; price:int; width_cm:float; height_cm:float; year:int; description:str; images:list[str]; featured:bool=False; status:ReviewStatus='pending'; review_note:str=''; availability:Availability='available'; subject:str=''; framed:bool=False; shipping_origin:str=''; certificate_available:bool=True; buy_now:bool=True; auction_eligible:bool=False; submitted_by:str=''; review_history:list[dict]=[]; ai_assisted:bool=False; created_at:datetime=Field(default_factory=_now); category:str=''; artforms:list[str]=[]; styles:list[str]=[]; subjects:list[str]=[]; collections:list[str]=[]; colours:list[str]=[]; taxonomy_verified:bool=False; is_demo:bool=False |
| `models/gallery.py` | `ArtworkSubmit` | title:str=Field(min_length=2); style:str; medium:str; price:int=Field(gt=0); width_cm:float=Field(gt=0); height_cm:float=Field(gt=0); year:int; description:str=Field(min_length=10); image:str=''; extra_images:list[str]=[]; media_ids:list[str]=[]; subject:str=''; framed:bool=False; shipping_origin:str=''; certificate_available:bool=True; auction_eligible:bool=False; originality_declared:bool=False; ai_assisted:bool=False; draft:bool=False |
| `models/gallery.py` | `ArtworkDetail` | artwork:Artwork; artist:Optional[Artist]=None; related:list[Artwork]=[] |
| `models/gallery.py` | `Bid` | bidder:str; amount:int; at:datetime; auto:bool=False |
| `models/gallery.py` | `AuctionResult` | outcome:Literal['sold', 'unsold']; hammer:int=0; winner_alias:str=''; reserve_met:bool=False; order_id:str='' |
| `models/gallery.py` | `Auction` | id:str; lot:str; title:str; artwork_id:str; artist_name:str; style:str; image:str; status:AuctionStatus; starts_at:datetime; ends_at:datetime; starting_bid:int; current_bid:int; increment:int; estimate_low:int; estimate_high:int; bids:list[Bid]=[]; is_demo:bool=True; description:str=''; artist_id:str=''; has_reserve:bool=False; reserve_met:bool=False; reserve_price:Optional[int]=None; buyer_premium_pct:float=0; bid_count:int=0; leader_alias:str=''; extended_count:int=0; result:Optional[AuctionResult]=None; my_max:Optional[int]=None; i_lead:bool=False |
| `models/gallery.py` | `BidCreate` | amount:int=Field(gt=0); max_amount:Optional[int]=Field(default=None, gt=0); idempotency_key:str=Field(min_length=8, max_length=64) |
| `models/gallery.py` | `EnquiryCreate` | artwork_id:str; name:str=Field(min_length=2); email:EmailStr; phone:str=''; message:str=Field(min_length=5); private_viewing:bool=False |
| `models/gallery.py` | `Enquiry` | id:str=Field(default_factory=_id); artwork_id:str; artwork_title:str; artist_id:str; name:str; email:str; phone:str=''; message:str; private_viewing:bool=False; status:EnquiryStatus='new'; created_at:datetime=Field(default_factory=_now) |
| `models/gallery.py` | `FilterMeta` | styles:list[str]; mediums:list[str]; counts:dict[str, dict[str, int]]={}; min_price:int; max_price:int |
| `models/gallery.py` | `Me` | user_id:str; role:str; permissions:list[str]=[]; email:str=''; name:str=''; artist:Optional[Artist]=None; intermediary_status:Optional[str]=None; bidder_status:Optional[str]=None; unread_notifications:int=0 |
| `models/gallery.py` | `Studio` | artist:Optional[Artist]=None; artworks:list[Artwork]=[]; enquiries:list[Enquiry]=[]; auctions:list[Auction]=[] |
| `models/gallery.py` | `ReviewUpdate` | status:ReviewStatus; note:str='' |
| `models/gallery.py` | `EnquiryStatusUpdate` | status:EnquiryStatus |
| `models/gallery.py` | `UserRow` | user_id:str; role:str; email:str=''; name:str='' |
| `models/gallery.py` | `UserList` | roles:list[str]; users:list[UserRow] |
| `models/gallery.py` | `RoleIn` | role:str |
| `models/gallery.py` | `AdminStats` | pending_artists:int; pending_artworks:int; new_enquiries:int; live_artworks:int; pending_intermediaries:int=0; active_auctions:int=0; pending_bidders:int=0; open_offers:int=0; open_orders:int=0; open_requests:int=0; test_revenue:int=0; test_commission:int=0 |
| `models/platform.py` | `HistoryEntry` | at:datetime; by:str=''; status:str=''; note:str=''; amount:Optional[int]=None |
| `models/platform.py` | `IdList` | ids:list[str] |
| `models/platform.py` | `OfferCreate` | artwork_id:str; amount:int=Field(gt=0); message:str='' |
| `models/platform.py` | `OfferAction` | action:Literal['forward', 'reject', 'accept', 'counter', 'expire', 'accept_counter', 'decline_counter']; amount:Optional[int]=Field(default=None, gt=0); note:str='' |
| `models/platform.py` | `Offer` | id:str; artwork_id:str; artwork_title:str; artwork_image:str=''; artist_id:str; list_price:int; buyer_user_id:str; buyer_name:str=''; buyer_email:str=''; amount:int; counter_amount:Optional[int]=None; message:str=''; status:OfferStatus; order_id:str=''; history:list[HistoryEntry]=[]; created_at:datetime |
| `models/platform.py` | `Address` | full_name:str=Field(min_length=2); phone:str=Field(min_length=6); line1:str=Field(min_length=3); city:str=Field(min_length=2); state:str=''; postal_code:str=Field(min_length=4); country:str='India' |
| `models/platform.py` | `CheckoutIn` | address:Address; notes:str=''; accept_terms:bool |
| `models/platform.py` | `OrderItem` | artwork_id:str; title:str; artist_id:str; artist_name:str; image:str=''; price:int |
| `models/platform.py` | `Ledger` | subtotal:int=0; discount:int=0; shipping:int=0; tax:int=0; buyer_premium:int=0; total:int=0; platform_commission:int=0; intermediary_commission:int=0; artist_payable:int=0; refunded:int=0 |
| `models/platform.py` | `Order` | id:str; number:str; kind:Literal['purchase', 'auction', 'offer', 'commission']; buyer_user_id:str; buyer_name:str=''; buyer_email:str=''; items:list[OrderItem]; ledger:Ledger; status:OrderStatus; address:Optional[Address]=None; payment_method:str='bank_transfer'; payment_reference:str=''; carrier:str=''; tracking_number:str=''; dispatched_at:Optional[datetime]=None; delivered_at:Optional[datetime]=None; shipping_document:str=''; settlement_status:Literal['not_due', 'pending', 'paid']='not_due'; certificate_number:str=''; test_mode:bool=True; timeline:list[HistoryEntry]=[]; created_at:datetime |
| `models/platform.py` | `ShippingIn` | action:Literal['dispatch', 'deliver']; carrier:str=''; tracking_number:str=''; dispatched_on:Optional[datetime]=None; document_url:str=''; note:str='' |
| `models/platform.py` | `OrderAction` | action:Literal['confirm_payment', 'dispatch', 'deliver', 'complete', 'cancel', 'refund', 'settle', 'shipping_quote']; reference:str=''; carrier:str=''; tracking_number:str=''; amount:Optional[int]=Field(default=None, ge=0); note:str='' |
| `models/platform.py` | `BidderRegister` | full_name:str=Field(min_length=2); phone:str=Field(min_length=6); city:str=Field(min_length=2); accept_terms:bool |
| `models/platform.py` | `BidderProfile` | user_id:str; full_name:str; email:str=''; phone:str=''; city:str=''; alias:str; status:BidderStatus; terms_version:str=''; created_at:datetime |
| `models/platform.py` | `StatusIn` | status:str; note:str='' |
| `models/platform.py` | `AuctionCreate` | artwork_id:str; title:str=''; description:str=''; starts_at:datetime; ends_at:datetime; starting_bid:int=Field(gt=0); increment:int=Field(gt=0); estimate_low:int=Field(gt=0); estimate_high:int=Field(gt=0); reserve_price:Optional[int]=Field(default=None, gt=0) |
| `models/platform.py` | `AuctionAdminAction` | action:Literal['pause', 'resume', 'close'] |
| `models/platform.py` | `MyBid` | auction_id:str; lot:str; title:str; image:str; status:str; my_top:int; current_bid:int; leading:bool; won:bool=False |
| `models/platform.py` | `RequestCreate` | type:RequestType; name:str=Field(min_length=2); email:EmailStr; phone:str=''; details:dict[str, str]={}; message:str=Field(min_length=5) |
| `models/platform.py` | `RequestUpdate` | status:Optional[RequestStatus]=None; note:str=''; quote_amount:Optional[int]=Field(default=None, ge=0); assigned_to:Optional[str]=None |
| `models/platform.py` | `ServiceRequest` | id:str; reference:str; type:RequestType; user_id:Optional[str]=None; name:str; email:str; phone:str=''; details:dict[str, str]={}; message:str; status:RequestStatus; quote_amount:Optional[int]=None; assigned_to:str=''; history:list[HistoryEntry]=[]; created_at:datetime |
| `models/platform.py` | `NewsletterIn` | email:EmailStr; consent:bool |
| `models/platform.py` | `NewsletterOut` | email:str; status:Literal['subscribed', 'unsubscribed'] |
| `models/platform.py` | `ArticleIn` | title:str=Field(min_length=3); excerpt:str=''; body:str=Field(min_length=10); cover:str=''; category:str='Artform guide'; tags:list[str]=[]; author:str='tRA Editorial'; status:Literal['draft', 'in_review', 'published']='draft'; seo_title:str=''; seo_description:str='' |
| `models/platform.py` | `Article` | id:str; slug:str; published_at:Optional[datetime]=None; created_at:datetime |
| `models/platform.py` | `CertificateIn` | artwork_id:str; declaration_type:Literal['artist_declaration', 'independently_verified']='artist_declaration'; owner_name:str=''; order_id:str=''; provenance:str='' |
| `models/platform.py` | `Certificate` | id:str; number:str; artwork_id:str; title:str; artist_name:str; medium:str; dimensions:str; year:int; image:str=''; declaration_type:str; owner_name:str=''; order_id:str=''; provenance:str=''; status:Literal['valid', 'revoked']='valid'; issued_at:datetime |
| `models/platform.py` | `IntermediaryRegister` | kind:Literal['individual_agent', 'art_consultant', 'gallery', 'artist_representative', 'agency', 'other', 'individual', 'business']; name:str=Field(min_length=2); business_name:str=''; phone:str=Field(min_length=6); location:str=Field(min_length=2); about:str=''; accept_agreement:bool |
| `models/platform.py` | `Intermediary` | id:str; user_id:str; kind:str; name:str; business_name:str=''; email:str=''; phone:str=''; location:str=''; about:str=''; status:Literal['pending', 'approved', 'rejected', 'suspended']; review_note:str=''; created_at:datetime |
| `models/platform.py` | `InviteIn` | artist_id:str; scopes:list[Literal['submit_artworks', 'manage_enquiries', 'view_sales', 'auction_submissions']]=Field(min_length=1); commission_pct:float=Field(ge=0, le=50); ends_on:Optional[datetime]=None; note:str='' |
| `models/platform.py` | `Representation` | id:str; intermediary_id:str; intermediary_name:str; artist_id:str; artist_name:str; scopes:list[str]; commission_pct:float; status:Literal['invited', 'active', 'declined', 'revoked', 'expired', 'terminated']; starts_on:Optional[datetime]=None; ends_on:Optional[datetime]=None; history:list[HistoryEntry]=[]; created_at:datetime; relationship_type:str='non_exclusive'; territory:str='India'; artwork_scope:str='all'; artwork_ids:list[str]=[]; services:list[str]=[]; commission_agreement_id:str=''; consent_timestamp:Optional[datetime]=None; created_by:str=''; approved_by:str=''; revoked_at:Optional[datetime]=None |
| `models/platform.py` | `RepresentationAction` | action:Literal['accept', 'decline', 'revoke']; note:str='' |
| `models/platform.py` | `IntermediaryDashboard` | profile:Optional[Intermediary]=None; representations:list[Representation]=[]; artworks:list[dict]=[]; enquiries:list[dict]=[]; sales:list[dict]=[] |
| `models/platform.py` | `Notification` | id:str; title:str; body:str=''; link:str=''; read:bool; created_at:datetime |
| `models/platform.py` | `AuditEntry` | id:str; actor_id:str; actor_email:str=''; action:str; entity:str; entity_id:str; detail:str=''; at:datetime |
| `models/platform.py` | `Flags` | real_money_enabled:bool; bidding_enabled:bool; auto_approve_bidders:bool; buy_now_enabled:bool; offers_enabled:bool; newsletter_enabled:bool |
| `models/platform.py` | `PlatformSettings` | brand_name:str; contact_email:str; contact_phone:str; currency:str; supported_countries:list[str]; platform_commission_pct:float=Field(ge=0, le=100); intermediary_commission_pct:float=Field(ge=0, le=100); buyer_premium_pct:float=Field(ge=0, le=100); gst_pct:float=Field(ge=0, le=100); domestic_shipping_fee:int=Field(ge=0); anti_snipe_window_min:int=Field(ge=0, le=60); anti_snipe_extend_min:int=Field(ge=0, le=60); default_bid_increment:int=Field(gt=0); commission_revision_limit:int=Field(ge=0, le=10); commission_deposit_pct:float=Field(default=40, ge=10, le=90); bank_transfer_instructions:str; flags:Flags; legal_versions:dict[str, str] |
| `models/platform.py` | `PublicSettings` | brand_name:str; contact_email:str; contact_phone:str; currency:str; buyer_premium_pct:float; gst_pct:float; flags:Flags; legal_versions:dict[str, str] |
| `models/platform.py` | `CartView` | items:list[dict]; subtotal:int; tax:int; shipping:int; total:int; unavailable:list[str]=[] |
| `models/platform.py` | `AccountSummary` | wishlist:list[dict]; offers:list[Offer]; orders:list[Order]; bids:list[MyBid]; requests:list[ServiceRequest]; bidder:Optional[BidderProfile]=None; certificates:list[Certificate]=[] |
| `models/platform.py` | `Reports` | verified_financials:bool; counts:dict[str, int]; revenue:dict[str, int]; orders_by_status:dict[str, int]; requests_by_type:dict[str, int]; bids_last_30d:int |
| `models/profile.py` | `InviteV2` | artist_id:str; relationship_type:Literal['non_exclusive', 'exclusive_territory', 'project', 'commission_only']='non_exclusive'; scopes:list[RepScope]=Field(min_length=1); commission_pct:float=Field(ge=0, le=50); territory:str='India'; artwork_scope:Literal['all', 'selected']='all'; artwork_ids:list[str]=[]; services:list[str]=[]; commission_agreement_id:str=''; starts_on:Optional[datetime]=None; ends_on:Optional[datetime]=None; note:str='' |
| `models/profile.py` | `ScopeUpdate` | scopes:list[RepScope]=Field(min_length=1); artwork_scope:Literal['all', 'selected']='all'; artwork_ids:list[str]=[]; territory:str='India'; ends_on:Optional[datetime]=None |
| `models/profile.py` | `ParticipationIn` | participation:Participation |
| `models/profile.py` | `Social` | instagram:str=''; facebook:str=''; x:str=''; linkedin:str=''; youtube:str='' |
| `models/profile.py` | `ProfileIn` | full_name:str=''; display_name:str=''; phone:str=''; alt_phone:str=''; date_of_birth:Optional[str]=None; country:str='India'; state:str=''; city:str=''; postal_address:str=''; language:str='English'; currency:str='INR'; timezone:str='Asia/Kolkata'; bio:str=Field(default='', max_length=1500); website:str=''; social:Social=Social() |
| `models/profile.py` | `Profile` | user_id:str; email:str=''; role:str; avatar:str=''; status:str='active'; email_verified:bool=False; phone_verified:bool=False; created_at:Optional[datetime]=None; last_login:Optional[datetime]=None; deactivation_requested:bool=False |
| `models/profile.py` | `Prefs` | account:bool=True; artwork_updates:bool=True; auction:bool=True; outbid:bool=True; offers:bool=True; orders:bool=True; commissions:bool=True; newsletter:bool=False; marketing:bool=False; show_profile_publicly:bool=False; show_collection_publicly:bool=False; analytics_cookies:bool=False |
| `models/profile.py` | `SessionRow` | id:str; status:str; last_active_at:Optional[datetime]=None; created_at:Optional[datetime]=None; browser:str=''; device:str=''; city:str=''; country:str=''; ip:str=''; current:bool=False |
| `models/profile.py` | `ArtistProfileExt` | legal_name:str=''; professional_name:str=''; display_name:str=''; phone:str=''; country:str='India'; state:str=''; city:str=''; studio_address:str=''; external_artist_id:str=''; registration_number:str=''; membership_number:str=''; years_experience:Optional[int]=Field(default=None, ge=0, le=90); primary_artform:str=''; secondary_artforms:list[str]=[]; specialisation:str=''; artistic_style:str=''; preferred_medium:str=''; biography:str=''; statement:str=''; education:str=''; training:str=''; exhibitions:str=''; awards:str=''; recognitions:str=''; memberships:str=''; website:str=''; social:Social=Social(); commission_available:bool=False; disclose_sold:bool=False; custom_available:bool=False; auction_participation:bool=False; shipping_origin:str=''; currency:str='INR'; portfolio_images:list[str]=[]; studio_photos:list[str]=[]; portfolio_pdf:str=''; cv_pdf:str=''; intro_video:str='' |
| `models/profile.py` | `ArtistProfileView` | artist_id:str; artist_code:str=''; public_reference:str=''; participation:str='independent'; profile:ArtistProfileExt; completeness:int; missing_required:list[str]=[]; field_config:dict[str, str]={}; identity_status:str='not_submitted'; portfolio_status:str='pending'; approval_status:str='pending'; approved_at:Optional[datetime]=None; approved_by:str=''; agreement_accepted:bool=False; originality_declared:bool=False; pending_changes:dict={}; finance:dict={} |
| `models/profile.py` | `FinanceIn` | account_name:str=Field(min_length=2); account_number:str=Field(min_length=6, max_length=20); ifsc:str=Field(pattern='^[A-Z]{4}0[A-Z0-9]{6}$'); pan:str=Field(default='', pattern='^$\|^[A-Z]{5}[0-9]{4}[A-Z]$'); gstin:str='' |
| `models/profile.py` | `PersonCreate` | email:EmailStr; full_name:str=Field(min_length=2); role:CreatableRole; grants:list[str]=[]; note:str='' |
| `models/profile.py` | `PersonUpdate` | full_name:Optional[str]=None; phone:Optional[str]=None; role:Optional[CreatableRole]=None; status:Optional[Literal['active', 'suspended', 'deactivated', 'archived']]=None; grants:Optional[list[str]]=None; revokes:Optional[list[str]]=None; reason:str='' |
| `models/profile.py` | `Person` | user_id:str=''; invite_id:str=''; email:str; name:str=''; role:str; status:str='active'; permissions:list[str]=[]; grants:list[str]=[]; revokes:list[str]=[]; last_login:Optional[datetime]=None; created_at:Optional[datetime]=None; created_by:str=''; artist_code:str='' |
| `models/profile.py` | `PeoplePage` | items:list[Person]; total:int; page:int; pages:int; counts:dict[str, int]={} |
| `models/profile.py` | `CertEvent` | at:datetime; by:str; action:str; note:str=''; version:int=1 |
| `models/profile.py` | `CertDoc` | id:str; number:str; token:str; type:CertType; artwork_id:str=''; artwork_title:str=''; artist_id:str=''; artist_name:str=''; uploaded_by:str; uploaded_by_name:str=''; uploader_role:str=''; issuer_name:str; issuer_org:str=''; issue_date:str; expiry_date:str=''; certificate_number:str=''; file_name:str=''; file_format:str=''; file_bytes:int=0; status:CertStatus; assurance:Assurance='artist_issued'; verification_notes:str=''; verified_by:str=''; verified_at:Optional[datetime]=None; version:int=1; revoked:bool=False; history:list[CertEvent]=[]; created_at:datetime |
| `models/profile.py` | `CertAction` | action:Literal['start_review', 'request_info', 'verify', 'reject', 'revoke', 'expire', 'supersede', 'reissue']; note:str=''; assurance:Optional[Assurance]=None |
| `models/profile.py` | `PublicCert` | status:str; number:str; type:str; artwork_title:str=''; artist_name:str=''; issue_date:str=''; verified_at:Optional[datetime]=None; issuer_name:str=''; issuer_org:str=''; assurance:str=''; assurance_label:str=''; image:str=''; source:Literal['document', 'platform_coa']='document' |
| `models/profile.py` | `LegalVersion` | doc_key:str; version:int; title:str; body:str; status:LegalStatus; material:bool=True; change_summary:str=''; created_by:str=''; created_at:datetime; approved_by:str=''; approved_at:Optional[datetime]=None; published_at:Optional[datetime]=None; counsel_reviewed:bool=False |
| `models/profile.py` | `LegalDoc` | key:str; title:str; roles:list[str]=[]; status:str; current_version:int; published_version:Optional[int]=None; updated_at:datetime; archived:bool=False |
| `models/profile.py` | `LegalDocDetail` | versions:list[LegalVersion] |
| `models/profile.py` | `LegalCreate` | key:str=Field(pattern='^[a-z][a-z0-9_]{2,40}$'); title:str=Field(min_length=3); body:str=Field(min_length=20); roles:list[str]=[] |
| `models/profile.py` | `LegalEdit` | title:str=Field(min_length=3); body:str=Field(min_length=20); change_summary:str=''; material:bool=True; roles:Optional[list[str]]=None |
| `models/profile.py` | `LegalAction` | action:Literal['submit', 'approve', 'publish', 'unpublish', 'archive', 'unarchive', 'restore', 'return_to_draft']; version:Optional[int]=None; counsel_reviewed:bool=False; note:str='' |
| `models/profile.py` | `PublicLegal` | key:str; title:str; version:int; status:str; body:str; published_at:Optional[datetime]=None; is_draft:bool |
| `models/profile.py` | `AcceptIn` | scope:str='account'; method:Literal['clickwrap', 'registration', 'checkout']='clickwrap' |
| `models/profile.py` | `AgreementStatus` | key:str; title:str; required_version:int; accepted_version:Optional[int]=None; accepted_at:Optional[datetime]=None; needs_acceptance:bool; is_draft:bool |
| `models/profile.py` | `Acceptance` | id:str; user_id:str; doc:str; version:str; at:datetime; method:str=''; role:str=''; scope:str='' |
| `models/profile.py` | `ArticleV2In` | title:str=Field(min_length=3); excerpt:str=''; body:str=Field(min_length=10); cover:str=''; image_credit:str=''; category:str='Artist Stories'; voice_type:str=''; tags:list[str]=[]; author:str='tRA Editorial'; author_id:str=''; related_artist_ids:list[str]=[]; related_artwork_ids:list[str]=[]; sources:list[str]=[]; featured:bool=False; seo_title:str=''; seo_description:str=''; video_url:str=''; ai_assisted:bool=False |
| `models/profile.py` | `ArticleV2` | id:str; slug:str; status:ArticleStatus='draft'; publish_at:Optional[datetime]=None; published_at:Optional[datetime]=None; created_at:datetime; updated_at:Optional[datetime]=None; views:int=0; reading_minutes:int=1; submitted_by_artist_id:str=''; artist_quote_approval:Literal['not_needed', 'pending', 'approved', 'changes_requested']='not_needed'; editorial_note:str=''; review_history:list[dict]=[] |
| `models/profile.py` | `ArticleCard` | id:str; slug:str; title:str; excerpt:str=''; cover:str=''; category:str; author:str; published_at:Optional[datetime]=None; reading_minutes:int=1; views:int=0; voice_type:str='' |
| `models/profile.py` | `JournalPage` | featured:Optional[ArticleCard]=None; items:list[ArticleCard]; popular:list[ArticleCard]; total:int; page:int; pages:int; categories:list[str] |
| `models/profile.py` | `ArticleView` | article:ArticleV2; related:list[ArticleCard]; artists:list[dict]; artworks:list[dict]; bookmarked:bool=False |
| `models/profile.py` | `ArticleAction` | action:Literal['submit', 'approve', 'publish', 'schedule', 'archive', 'unpublish', 'send_to_artist', 'request_changes']; publish_at:Optional[datetime]=None; note:str='' |
| `models/profile.py` | `StoryIn` | title:str=Field(min_length=3); body:str=Field(min_length=200); excerpt:str=''; voice_type:str='Studio Story'; related_artwork_ids:list[str]=[]; cover:str=''; video_url:str=''; artist_id:str='' |
| `models/profile.py` | `QuoteApproval` | approve:bool; note:str='' |
| `models/profile.py` | `Author` | id:str=''; name:str=Field(min_length=2); bio:str=''; avatar:str='' |
| `routers/admin.py` | `AccessIn` | status:Literal['active', 'suspended']='active'; grants:list[str]=[]; revokes:list[str]=[] |
| `routers/commissions.py` | `StartIn` | request_id:str; artist_id:str |
| `routers/commissions.py` | `QuoteIn` | amount:int=Field(gt=0); deposit_pct:Optional[float]=Field(default=None, ge=10, le=90); deadline:datetime; note:str='' |
| `routers/commissions.py` | `ActionIn` | action:Literal['accept_quote', 'decline_quote', 'progress', 'submit_for_review', 'request_revision', 'approve_final', 'ship', 'complete', 'cancel', 'mark_paid', 'settle']; note:str=''; images:list[str]=[]; milestone_id:str=''; carrier:str=''; tracking_number:str='' |
| `routers/media.py` | `SignIn` | purpose:str='artwork' |
| `routers/media.py` | `RegisterIn` | public_id:str; version:int; signature:str; width:int; height:int; format:str; bytes:int; original_filename:str='' |
| `routers/payments.py` | `VerifyIn` | razorpay_order_id:str; razorpay_payment_id:str; razorpay_signature:str |
| `routers/profiles.py` | `Crop` | x:int=0; y:int=0; size:int=0 |
| `routers/profiles.py` | `DeactivationIn` | reason:str='' |
| `routers/profiles.py` | `VerifyIn` | target:Literal['identity', 'portfolio', 'pending_changes', 'finance']; approve:bool; note:str='' |
| `routers/studio.py` | `ArtistRegisterIn` | participation:Literal['independent', 'represented', 'both']='independent'; accept_agreement:bool=False; originality_declared:bool=False; statement:str=''; education:str=''; exhibitions:str=''; awards:str=''; social:str=''; commissions_open:bool=False |
| `routers/studio.py` | `ArtworkEdit` | action:Literal['withdraw', 'resubmit', 'images']; images:list[str]=[] |

## Coverage gate

- Source business operations: **214**.
- Crosswalk rows: **214**.
- Unaccounted business operations: **0**.
- Clerk-only compatibility routes: **2**, explicitly retired.
- The 128-operation and 89-operation historical counts are superseded.
