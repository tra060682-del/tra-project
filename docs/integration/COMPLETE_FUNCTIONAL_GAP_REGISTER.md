# Complete functional gap register

## Consolidated application gap register

This file is the master index for the complete audit. Detailed source/current references, root cause, correction, dependencies, acceptance criteria and test requirements are held in the named register and linked by stable IDs. The IDs are unique across the audit; overlapping symptoms are not counted twice within a register.

| Register | IDs | P0 | P1 | P2 | P3 | Total |
|---|---|---:|---:|---:|---:|---:|
| Functional operations | `FUNC-001`–`FUNC-020` | 8 | 8 | 3 | 1 | 20 |
| Visual/UI | `VIS-001`–`VIS-024` | 3 | 15 | 4 | 2 | 24 |
| Data/schema/content | `DATA-001`–`DATA-014` | 3 | 8 | 3 | 0 | 14 |
| Dashboard workflows | `DASH-001`–`DASH-043` | 10 | 31 | 2 | 0 | 43 |
| Quarantined media rights | `MED-001`–`MED-023` | 0 | 17 | 6 | 0 | 23 |
| **Total unique gaps** |  | **24** | **79** | **18** | **3** | **124** |

Dashboard P0s are `DASH-001/002/003/005/019/020/021/029/030/035`; P2s are `DASH-014/015`; all other dashboard gaps are P1. Media P2s are fallback/editorial-only `MED-001/004/008/011/012/013`; the other 17 media gaps are P1 because they block artwork, auction, taxonomy or broad journal parity.

Severity means: P0 core product unusable/missing; P1 major visual or functional discrepancy; P2 important non-blocking discrepancy; P3 polish. Security-gated features are still gaps relative to Emergent, but their disabled state is correct until the dependency is approved.

## Authoritative operation coverage

`API_ENDPOINT_CROSSWALK.md` is retained as the exhaustive contract for all **214** Emergent business operations: method, route, role/authentication, request/response schema, database dependencies, business rules/errors, historical Next equivalent, migration approach and required tests. This audit rechecked every numbered row against the current source.

Current active-equivalence classification:

| Classification | Operations | Meaning |
|---|---:|---|
| Equivalent | 1 | Contact submission has a real server action/RPC equivalent; outbound delivery remains a separate disabled concern. |
| Partially equivalent | 60 | A page/action/read path exists, but source behaviour, fields, persistence, feedback or tests are incomplete. |
| Missing active equivalent | 153 | No active equivalent; some have migration-ready contracts/adapters but are disabled/blocked and therefore not functional parity. |
| **Total** | **214** | Every authoritative operation is represented in the appendix below. |

The classification deliberately does not count a TypeScript interface, provider adapter, disabled control, or API-shaped file as an operational equivalent.

## Domain coverage

| Domain | Operation rows | Count | Consolidated gap | Present state |
|---|---:|---:|---|---|
| Admin | 1–12 | 12 | FUNC-001 | Marketplace reviews partial; stats/user access incomplete or gated. |
| AI | 13–18 | 6 | FUNC-002 | No approved AI provider/usage workflow; catalogue chat absent. |
| Attribution | 19–20 | 2 | FUNC-003 | Queue/decision workflow missing. |
| Auctions | 21–32 | 12 | FUNC-004 | Reads/watch/bid foundation partial; launch/real-money actions intentionally disabled. |
| Certificates/documents | 33–39 | 7 | FUNC-005 | Private/admin/public verification contracts gated by migration/storage policy. |
| Commerce | 40–59 | 20 | FUNC-006 | Typed contracts/UI exist; most writes need unapplied transactional schema/RPCs. |
| Commissions | 60–65 | 6 | FUNC-007 | Service intake partial; quote/milestone/financial lifecycle missing. |
| Cron | 66 | 1 | FUNC-008 | Contracts/adapters only; no active scheduler. |
| Discovery | 67–97 | 31 | FUNC-009 | Public catalogue reads partial; taxonomy/collections/search/admin discovery incomplete. |
| Intermediary | 98–109 | 12 | FUNC-010 | Profile/request partial; consent/scope/delegated data blocked by unapplied RLS/RPC. |
| Journal | 110–125 | 16 | FUNC-011 | Public/admin shells partial; authoring, approval, quotes and media workflows incomplete. |
| Legal | 126–136 | 11 | FUNC-012 | Some baseline acceptance; versioned centre/admin publication incomplete. |
| Media | 137–143 | 7 | FUNC-013 | Provider-independent storage exists, but no active signed upload/scan/approval pipeline. |
| Payments | 144–149 | 6 | FUNC-014 | Sandbox adapters are disabled; no provider objects, callbacks or real reconciliation. |
| People | 150–157 | 8 | FUNC-015 | Inspection partial; invitation/role/status mutations and identity link are approval-gated. |
| Profiles | 158–175 | 18 | FUNC-016 | Role profiles partial; source fields/preferences/verification flows incomplete. |
| Public | 176–182 | 7 | FUNC-017 | Settings/health/newsletter/public ancillary operations incomplete or disabled. |
| Server | 183 | 1 | FUNC-018 | Source root/health behaviour differs from Next deployment diagnostics. |
| Services | 184–207 | 24 | FUNC-019 | Contact is equivalent; enquiries/newsletter/requests/notifications are partial or provider-blocked. |
| Studio | 208–214 | 7 | FUNC-020 | Profile/artwork core partial; draft/enquiries/offers/sales require further contracts. |

## Consolidated functional gaps

| Gap ID | Severity | Source reference | Current reference | Root cause | Required correction | Dependencies | Acceptance/test |
|---|---:|---|---|---|---|---|---|
| FUNC-001 | P0 | admin ops 1–12 | `/admin/*` actions/pages | Distributed partial port and unapplied Phase 3 enforcement | Reconcile every source field/action and secure mutation | Phase 3 migration/bootstrap | permitted/denied role, suspension, no self-escalation, audit tests |
| FUNC-002 | P2 | AI 13–18 | none | provider/policy absent | Implement only after AI purpose, provider and audit approval | provider, usage schema | rate, prompt/output bound, attribution and failure tests |
| FUNC-003 | P1 | attribution 19–20 | none | missing schema/UI | Append-only evidence/decision queue | Phase 1 content schema | immutable evidence and no placeholder impersonation |
| FUNC-004 | P0 | auctions 21–32 | auction reads, bid/watch routes, admin preview | source operational state machine not activated | Complete preview parity; preserve database concurrency and launch gate | applied auction contracts, legal/financial approval | simultaneous bid/close/eligibility/finance-role tests |
| FUNC-005 | P1 | certdocs 33–39 | disabled certificate/private-media surfaces | disclosure/storage migrations absent | Implement issuer/version/revocation and filtered verifier | certificate RPC, private storage | enumeration, token entropy, revocation, field filtering |
| FUNC-006 | P0 | commerce 40–59 | `commerce/actions.ts`, commerce pages/contracts | 22-table proposal unapplied | Apply approved transactional model then connect UI | Phase 3 then Phase 6A migration, policies | concurrency, idempotency, money, ownership tests |
| FUNC-007 | P1 | commissions 60–65 | enquiry intake only | workflow and financial policy missing | Implement assignment, quote, milestones, acceptance and audit | commission policy/schema | transition/role/money tests |
| FUNC-008 | P2 | cron 66 | local/sandbox scheduling contracts | Cloudflare Cron not activated | Approved worker-only schedule with replay locks | queue/cron approval | overlap, replay, partial failure tests |
| FUNC-009 | P0 | discovery 67–97 | public routes/catalogue, limited admin | empty public data and missing relationship schema/admin UI | Complete catalogue/search/taxonomy/collection behaviour | content migration, approved data/media | 33/27 reconciliation, filter/search/order and anonymous RLS tests |
| FUNC-010 | P0 | intermediary 98–109 | intermediary pages/actions | scoped database enforcement unapplied | Implement consent, scope, expiry/revocation and delegated projections | Phase 3 RLS/RPC | immediate revocation and cross-artist isolation tests |
| FUNC-011 | P1 | journal 110–125 | public/admin content pages | no approved data; CMS/quote/media incomplete | Port public/editorial workflow with approval states | content schema, media rights | author/reviewer/publish/quote/media tests |
| FUNC-012 | P1 | legal 126–136 | static legal pages and onboarding acceptance | generic version/publication APIs incomplete | Versioned legal centre and immutable acceptance | legal migration/approval | hash/version/effective date/cross-user tests |
| FUNC-013 | P1 | media 137–143 | provider adapters, disabled upload UI | R2/scanner/provider not approved | Signed purpose-bound upload, quarantine, review, deletion constraints | storage/scanner approval | MIME/size/owner/scan/signed expiry tests |
| FUNC-014 | P0 | payments 144–149 | disabled Razorpay/Stripe adapters | no provider approval; finance schema unapplied | Connect approved sandbox only after DB/policy readiness | provider secrets, webhook, ledger | signature/replay/amount/currency/idempotency/reconcile tests |
| FUNC-015 | P0 | people 150–157 | `/admin/access`, auth actions | bootstrap/linking/invite policy and DB enforcement gated | Apply secure role/status/invite contracts; never email-based privilege | Phase 3 migration, email provider | self/last-admin, revocation, duplicate identity tests |
| FUNC-016 | P1 | profiles 158–175 | `/profile`, artist/intermediary/account forms | split/incomplete field and verification model | Crosswalk exact fields, ownership and private-document handling | profile migration/private media | role/owner/document/privacy tests |
| FUNC-017 | P2 | public 176–182 | settings/health/local newsletter surfaces | settings/delivery provider absent | Implement approved safe projections and honest delivery status | settings RPC/email | anonymous disclosure, consent, idempotency tests |
| FUNC-018 | P3 | server 183 | Next health/build diagnostics | framework architecture differs | Document/implement equivalent health semantics without leaking config | monitoring approval | response/redaction tests |
| FUNC-019 | P1 | services 184–207 | enquiry action, notification/email adapters | only contact core equivalent; other workflows incomplete | Complete intake/status/assignment/notification with server validation | enquiry schema/email/queue | spam/rate/consent/ownership/delivery tests |
| FUNC-020 | P0 | studio 208–214 | artist pages/actions | submission core exists; lifecycle/commerce/media incomplete | Port exact source fields/states/panels under server auth | content/commerce/media migrations | ownership/legal/status/upload/offer/sale tests |

## Operation-by-operation current status

The compact appendix below maps every numbered authoritative contract to its current audit classification and consolidated gap. Full schemas, roles, rules and tests remain in `API_ENDPOINT_CROSSWALK.md` and are not duplicated inaccurately here.

| Operation | Method and route | Current classification | Gap |
|---:|---|---|---|
| 1 | `GET /api/admin/artists` | Partially equivalent | FUNC-001 |
| 2 | `PATCH /api/admin/artists/{id}/status` | Partially equivalent | FUNC-001 |
| 3 | `GET /api/admin/artworks` | Partially equivalent | FUNC-001 |
| 4 | `PATCH /api/admin/artworks/{id}/featured` | Partially equivalent | FUNC-001 |
| 5 | `PATCH /api/admin/artworks/{id}/status` | Partially equivalent | FUNC-001 |
| 6 | `GET /api/admin/enquiries` | Partially equivalent | FUNC-001 |
| 7 | `PATCH /api/admin/enquiries/{id}/status` | Partially equivalent | FUNC-001 |
| 8 | `GET /api/admin/stats` | Missing active equivalent | FUNC-001 |
| 9 | `GET /api/users` | Missing active equivalent | FUNC-001 |
| 10 | `GET /api/users/{user_id}/access` | Missing active equivalent | FUNC-001 |
| 11 | `PATCH /api/users/{user_id}/access` | Missing active equivalent | FUNC-001 |
| 12 | `PATCH /api/users/{user_id}/role` | Missing active equivalent | FUNC-001 |
| 13 | `POST /api/admin/ai/artworks/{id}/taxonomy-suggestions` | Missing active equivalent | FUNC-002 |
| 14 | `POST /api/admin/ai/journal-draft` | Missing active equivalent | FUNC-002 |
| 15 | `GET /api/admin/ai/usage` | Missing active equivalent | FUNC-002 |
| 16 | `POST /api/ai/artwork-description` | Missing active equivalent | FUNC-002 |
| 17 | `POST /api/artworks/{id}/ask` | Partially equivalent | FUNC-002 |
| 18 | `GET /api/artworks/{id}/ask/{session_id}` | Partially equivalent | FUNC-002 |
| 19 | `GET /api/admin/attribution-reviews` | Missing active equivalent | FUNC-003 |
| 20 | `POST /api/admin/attribution-reviews/{id}/decision` | Missing active equivalent | FUNC-003 |
| 21 | `GET /api/admin/auctions` | Partially equivalent | FUNC-004 |
| 22 | `POST /api/admin/auctions` | Partially equivalent | FUNC-004 |
| 23 | `POST /api/admin/auctions/{id}/action` | Partially equivalent | FUNC-004 |
| 24 | `GET /api/admin/bidders` | Partially equivalent | FUNC-004 |
| 25 | `PATCH /api/admin/bidders/{user_id}` | Partially equivalent | FUNC-004 |
| 26 | `GET /api/auctions` | Partially equivalent | FUNC-004 |
| 27 | `GET /api/auctions/{id}` | Partially equivalent | FUNC-004 |
| 28 | `POST /api/auctions/{id}/bids` | Partially equivalent | FUNC-004 |
| 29 | `POST /api/auctions/{id}/watch` | Partially equivalent | FUNC-004 |
| 30 | `GET /api/bidder` | Partially equivalent | FUNC-004 |
| 31 | `POST /api/bidder` | Partially equivalent | FUNC-004 |
| 32 | `GET /api/me/watchlist` | Partially equivalent | FUNC-004 |
| 33 | `GET /api/admin/cert-docs` | Missing active equivalent | FUNC-005 |
| 34 | `POST /api/admin/cert-docs/{id}/action` | Missing active equivalent | FUNC-005 |
| 35 | `POST /api/cert-docs` | Missing active equivalent | FUNC-005 |
| 36 | `GET /api/cert-docs/mine` | Missing active equivalent | FUNC-005 |
| 37 | `GET /api/cert-docs/{id}/file` | Missing active equivalent | FUNC-005 |
| 38 | `POST /api/cert-docs/{id}/versions` | Missing active equivalent | FUNC-005 |
| 39 | `GET /api/verify-certificate` | Missing active equivalent | FUNC-005 |
| 40 | `GET /api/account` | Missing active equivalent | FUNC-006 |
| 41 | `GET /api/admin/offers` | Missing active equivalent | FUNC-006 |
| 42 | `GET /api/admin/orders` | Missing active equivalent | FUNC-006 |
| 43 | `POST /api/admin/orders/{id}/action` | Missing active equivalent | FUNC-006 |
| 44 | `GET /api/cart` | Missing active equivalent | FUNC-006 |
| 45 | `DELETE /api/cart/{artwork_id}` | Missing active equivalent | FUNC-006 |
| 46 | `POST /api/cart/{artwork_id}` | Missing active equivalent | FUNC-006 |
| 47 | `POST /api/checkout` | Missing active equivalent | FUNC-006 |
| 48 | `GET /api/intermediary/offers` | Partially equivalent | FUNC-006 |
| 49 | `GET /api/me/wishlist` | Missing active equivalent | FUNC-006 |
| 50 | `POST /api/me/wishlist/{artwork_id}` | Missing active equivalent | FUNC-006 |
| 51 | `GET /api/notifications` | Missing active equivalent | FUNC-006 |
| 52 | `POST /api/notifications/read` | Missing active equivalent | FUNC-006 |
| 53 | `POST /api/offers` | Missing active equivalent | FUNC-006 |
| 54 | `GET /api/offers/mine` | Missing active equivalent | FUNC-006 |
| 55 | `POST /api/offers/{id}/action` | Missing active equivalent | FUNC-006 |
| 56 | `GET /api/orders` | Missing active equivalent | FUNC-006 |
| 57 | `POST /api/orders/{id}/shipping` | Missing active equivalent | FUNC-006 |
| 58 | `GET /api/shipping` | Missing active equivalent | FUNC-006 |
| 59 | `GET /api/studio/offers` | Partially equivalent | FUNC-006 |
| 60 | `GET /api/admin/commissions` | Missing active equivalent | FUNC-007 |
| 61 | `POST /api/admin/commissions` | Missing active equivalent | FUNC-007 |
| 62 | `GET /api/commissions` | Missing active equivalent | FUNC-007 |
| 63 | `POST /api/commissions/{id}/action` | Missing active equivalent | FUNC-007 |
| 64 | `POST /api/commissions/{id}/pay` | Missing active equivalent | FUNC-007 |
| 65 | `POST /api/commissions/{id}/quote` | Missing active equivalent | FUNC-007 |
| 66 | `POST /api/cron/{job}` | Missing active equivalent | FUNC-008 |
| 67 | `GET /api/admin/analytics` | Missing active equivalent | FUNC-009 |
| 68 | `GET /api/admin/artwork-taxonomy` | Missing active equivalent | FUNC-009 |
| 69 | `PUT /api/admin/artworks/{id}/taxonomy` | Partially equivalent | FUNC-009 |
| 70 | `PUT /api/admin/discovery-settings` | Missing active equivalent | FUNC-009 |
| 71 | `GET /api/admin/featured-artists` | Missing active equivalent | FUNC-009 |
| 72 | `POST /api/admin/featured-artists` | Missing active equivalent | FUNC-009 |
| 73 | `DELETE /api/admin/featured-artists/{id}` | Missing active equivalent | FUNC-009 |
| 74 | `GET /api/admin/homepage` | Missing active equivalent | FUNC-009 |
| 75 | `PUT /api/admin/homepage` | Missing active equivalent | FUNC-009 |
| 76 | `GET /api/admin/homepage/preview` | Missing active equivalent | FUNC-009 |
| 77 | `POST /api/admin/homepage/publish` | Missing active equivalent | FUNC-009 |
| 78 | `GET /api/admin/taxonomy` | Missing active equivalent | FUNC-009 |
| 79 | `POST /api/admin/taxonomy` | Missing active equivalent | FUNC-009 |
| 80 | `PUT /api/admin/taxonomy/{id}` | Missing active equivalent | FUNC-009 |
| 81 | `GET /api/admin/testimonials` | Missing active equivalent | FUNC-009 |
| 82 | `POST /api/admin/testimonials` | Missing active equivalent | FUNC-009 |
| 83 | `PUT /api/admin/testimonials/{id}` | Missing active equivalent | FUNC-009 |
| 84 | `POST /api/admin/testimonials/{id}/action` | Missing active equivalent | FUNC-009 |
| 85 | `GET /api/admin/whatsapp` | Missing active equivalent | FUNC-009 |
| 86 | `PUT /api/admin/whatsapp` | Missing active equivalent | FUNC-009 |
| 87 | `GET /api/artists/{id}/page` | Partially equivalent | FUNC-009 |
| 88 | `GET /api/discover/artists` | Missing active equivalent | FUNC-009 |
| 89 | `GET /api/discover/facets` | Missing active equivalent | FUNC-009 |
| 90 | `GET /api/discover/settings` | Missing active equivalent | FUNC-009 |
| 91 | `GET /api/homepage` | Missing active equivalent | FUNC-009 |
| 92 | `GET /api/support/whatsapp` | Missing active equivalent | FUNC-009 |
| 93 | `GET /api/taxonomy` | Missing active equivalent | FUNC-009 |
| 94 | `GET /api/taxonomy/{kind}/{slug}` | Missing active equivalent | FUNC-009 |
| 95 | `GET /api/testimonials` | Missing active equivalent | FUNC-009 |
| 96 | `POST /api/testimonials` | Missing active equivalent | FUNC-009 |
| 97 | `POST /api/track` | Missing active equivalent | FUNC-009 |
| 98 | `GET /api/admin/intermediaries` | Missing active equivalent | FUNC-010 |
| 99 | `PATCH /api/admin/intermediaries/{id}` | Missing active equivalent | FUNC-010 |
| 100 | `GET /api/admin/representations` | Missing active equivalent | FUNC-010 |
| 101 | `POST /api/admin/representations/{id}/terminate` | Missing active equivalent | FUNC-010 |
| 102 | `GET /api/intermediary` | Partially equivalent | FUNC-010 |
| 103 | `POST /api/intermediary/artworks/{artist_id}` | Partially equivalent | FUNC-010 |
| 104 | `PUT /api/intermediary/artworks/{id}/draft` | Partially equivalent | FUNC-010 |
| 105 | `POST /api/intermediary/invites` | Partially equivalent | FUNC-010 |
| 106 | `POST /api/intermediary/register` | Partially equivalent | FUNC-010 |
| 107 | `POST /api/representations/{id}/action` | Partially equivalent | FUNC-010 |
| 108 | `PUT /api/representations/{id}/scopes` | Partially equivalent | FUNC-010 |
| 109 | `GET /api/studio/representations` | Partially equivalent | FUNC-010 |
| 110 | `GET /api/admin/journal` | Missing active equivalent | FUNC-011 |
| 111 | `POST /api/admin/journal` | Missing active equivalent | FUNC-011 |
| 112 | `POST /api/admin/journal-authors` | Missing active equivalent | FUNC-011 |
| 113 | `PUT /api/admin/journal-categories` | Missing active equivalent | FUNC-011 |
| 114 | `POST /api/admin/journal-tags/rename` | Missing active equivalent | FUNC-011 |
| 115 | `GET /api/admin/journal-taxonomy` | Missing active equivalent | FUNC-011 |
| 116 | `PUT /api/admin/journal/{id}` | Missing active equivalent | FUNC-011 |
| 117 | `POST /api/admin/journal/{id}/action` | Missing active equivalent | FUNC-011 |
| 118 | `GET /api/journal` | Missing active equivalent | FUNC-011 |
| 119 | `GET /api/journal/{slug}` | Missing active equivalent | FUNC-011 |
| 120 | `GET /api/me/journal-bookmarks` | Missing active equivalent | FUNC-011 |
| 121 | `DELETE /api/me/journal-bookmarks/{slug}` | Missing active equivalent | FUNC-011 |
| 122 | `POST /api/me/journal-bookmarks/{slug}` | Missing active equivalent | FUNC-011 |
| 123 | `GET /api/studio/stories` | Partially equivalent | FUNC-011 |
| 124 | `POST /api/studio/stories` | Partially equivalent | FUNC-011 |
| 125 | `POST /api/studio/stories/{id}/quote-approval` | Partially equivalent | FUNC-011 |
| 126 | `GET /api/admin/legal` | Missing active equivalent | FUNC-012 |
| 127 | `POST /api/admin/legal` | Missing active equivalent | FUNC-012 |
| 128 | `GET /api/admin/legal-acceptances` | Missing active equivalent | FUNC-012 |
| 129 | `GET /api/admin/legal/{key}` | Missing active equivalent | FUNC-012 |
| 130 | `PUT /api/admin/legal/{key}` | Missing active equivalent | FUNC-012 |
| 131 | `POST /api/admin/legal/{key}/action` | Missing active equivalent | FUNC-012 |
| 132 | `GET /api/legal-docs` | Partially equivalent | FUNC-012 |
| 133 | `GET /api/legal-docs/{key}` | Partially equivalent | FUNC-012 |
| 134 | `POST /api/legal-docs/{key}/accept` | Partially equivalent | FUNC-012 |
| 135 | `GET /api/me/acceptances` | Partially equivalent | FUNC-012 |
| 136 | `GET /api/me/agreements` | Missing active equivalent | FUNC-012 |
| 137 | `GET /api/admin/media` | Missing active equivalent | FUNC-013 |
| 138 | `PATCH /api/admin/media/{id}` | Missing active equivalent | FUNC-013 |
| 139 | `GET /api/uploads/config` | Missing active equivalent | FUNC-013 |
| 140 | `POST /api/uploads/register` | Missing active equivalent | FUNC-013 |
| 141 | `POST /api/uploads/sign` | Missing active equivalent | FUNC-013 |
| 142 | `DELETE /api/uploads/{id}` | Missing active equivalent | FUNC-013 |
| 143 | `GET /api/uploads/{id}/original` | Missing active equivalent | FUNC-013 |
| 144 | `GET /api/admin/payments` | Missing active equivalent | FUNC-014 |
| 145 | `GET /api/payments/config` | Missing active equivalent | FUNC-014 |
| 146 | `GET /api/payments/mine` | Missing active equivalent | FUNC-014 |
| 147 | `POST /api/payments/orders/{order_id}` | Missing active equivalent | FUNC-014 |
| 148 | `POST /api/payments/verify` | Missing active equivalent | FUNC-014 |
| 149 | `POST /api/payments/webhook` | Missing active equivalent | FUNC-014 |
| 150 | `GET /api/admin/people` | Missing active equivalent | FUNC-015 |
| 151 | `POST /api/admin/people` | Missing active equivalent | FUNC-015 |
| 152 | `POST /api/admin/people/invites/{invite_id}/revoke` | Missing active equivalent | FUNC-015 |
| 153 | `PATCH /api/admin/people/{user_id}` | Missing active equivalent | FUNC-015 |
| 154 | `GET /api/admin/people/{user_id}/history` | Missing active equivalent | FUNC-015 |
| 155 | `POST /api/admin/people/{user_id}/recover` | Missing active equivalent | FUNC-015 |
| 156 | `GET /api/me/sessions` | Missing active equivalent | FUNC-015 |
| 157 | `POST /api/me/sessions/{sid}/revoke` | Missing active equivalent | FUNC-015 |
| 158 | `GET /api/admin/artist-fields` | Missing active equivalent | FUNC-016 |
| 159 | `PUT /api/admin/artist-fields` | Missing active equivalent | FUNC-016 |
| 160 | `GET /api/admin/artists/{id}/profile` | Partially equivalent | FUNC-016 |
| 161 | `POST /api/admin/artists/{id}/verify` | Partially equivalent | FUNC-016 |
| 162 | `POST /api/files` | Missing active equivalent | FUNC-016 |
| 163 | `DELETE /api/me/avatar` | Missing active equivalent | FUNC-016 |
| 164 | `POST /api/me/avatar` | Missing active equivalent | FUNC-016 |
| 165 | `DELETE /api/me/deactivation` | Missing active equivalent | FUNC-016 |
| 166 | `POST /api/me/deactivation` | Missing active equivalent | FUNC-016 |
| 167 | `GET /api/me/prefs` | Missing active equivalent | FUNC-016 |
| 168 | `PUT /api/me/prefs` | Missing active equivalent | FUNC-016 |
| 169 | `GET /api/me/profile` | Missing active equivalent | FUNC-016 |
| 170 | `PUT /api/me/profile` | Missing active equivalent | FUNC-016 |
| 171 | `PUT /api/studio/finance` | Partially equivalent | FUNC-016 |
| 172 | `POST /api/studio/identity` | Partially equivalent | FUNC-016 |
| 173 | `PUT /api/studio/participation` | Partially equivalent | FUNC-016 |
| 174 | `GET /api/studio/profile` | Partially equivalent | FUNC-016 |
| 175 | `PUT /api/studio/profile` | Partially equivalent | FUNC-016 |
| 176 | `GET /api/artists` | Partially equivalent | FUNC-017 |
| 177 | `GET /api/artists/{id}` | Partially equivalent | FUNC-017 |
| 178 | `GET /api/artworks` | Partially equivalent | FUNC-017 |
| 179 | `GET /api/artworks/{id}` | Partially equivalent | FUNC-017 |
| 180 | `POST /api/enquiries` | Equivalent | FUNC-017 |
| 181 | `GET /api/meta/filters` | Partially equivalent | FUNC-017 |
| 182 | `GET /api/search` | Missing active equivalent | FUNC-017 |
| 183 | `GET /api/` | Missing active equivalent | FUNC-018 |
| 184 | `GET /api/admin/audit` | Missing active equivalent | FUNC-019 |
| 185 | `GET /api/admin/certificates` | Missing active equivalent | FUNC-019 |
| 186 | `POST /api/admin/certificates` | Missing active equivalent | FUNC-019 |
| 187 | `PATCH /api/admin/certificates/{id}` | Missing active equivalent | FUNC-019 |
| 188 | `GET /api/admin/email-log` | Missing active equivalent | FUNC-019 |
| 189 | `GET /api/admin/email-stats` | Missing active equivalent | FUNC-019 |
| 190 | `POST /api/admin/email/retry` | Missing active equivalent | FUNC-019 |
| 191 | `GET /api/admin/integrations` | Missing active equivalent | FUNC-019 |
| 192 | `POST /api/admin/newsletter/send` | Missing active equivalent | FUNC-019 |
| 193 | `GET /api/admin/reports` | Missing active equivalent | FUNC-019 |
| 194 | `GET /api/admin/requests` | Missing active equivalent | FUNC-019 |
| 195 | `PATCH /api/admin/requests/{id}` | Missing active equivalent | FUNC-019 |
| 196 | `GET /api/admin/settings` | Missing active equivalent | FUNC-019 |
| 197 | `PUT /api/admin/settings` | Missing active equivalent | FUNC-019 |
| 198 | `GET /api/certificates/{number}` | Missing active equivalent | FUNC-019 |
| 199 | `GET /api/legal` | Partially equivalent | FUNC-019 |
| 200 | `GET /api/me/email-prefs` | Missing active equivalent | FUNC-019 |
| 201 | `PUT /api/me/email-prefs` | Missing active equivalent | FUNC-019 |
| 202 | `POST /api/newsletter` | Missing active equivalent | FUNC-019 |
| 203 | `POST /api/newsletter/unsubscribe` | Missing active equivalent | FUNC-019 |
| 204 | `POST /api/newsletter/unsubscribe-token/{token}` | Missing active equivalent | FUNC-019 |
| 205 | `POST /api/requests` | Missing active equivalent | FUNC-019 |
| 206 | `GET /api/settings/public` | Partially equivalent | FUNC-019 |
| 207 | `GET /api/sitemap.xml` | Missing active equivalent | FUNC-019 |
| 208 | `POST /api/artists/register` | Partially equivalent | FUNC-020 |
| 209 | `GET /api/me` | Missing active equivalent | FUNC-020 |
| 210 | `GET /api/studio` | Partially equivalent | FUNC-020 |
| 211 | `POST /api/studio/artworks` | Partially equivalent | FUNC-020 |
| 212 | `PATCH /api/studio/artworks/{id}` | Partially equivalent | FUNC-020 |
| 213 | `PUT /api/studio/artworks/{id}/draft` | Partially equivalent | FUNC-020 |
| 214 | `GET /api/studio/sales` | Partially equivalent | FUNC-020 |

## Completion rule

An operation becomes equivalent only after the real user journey, server validation, permission/ownership boundary, persistence, error feedback and required tests are demonstrated. Database enforcement must be tested against an appropriate PostgreSQL/Supabase environment; mocked tests cannot close an RLS gap.
