# Schema gap analysis

Status: design only. The comparison uses the read-only development schema snapshot dated 2026-11-14. Existing objects remain unchanged.

## Design principles

- Extend existing production-compatible tables before creating a new entity.
- Never execute the Emergent `docs/schema.sql` wholesale; it duplicates and weakens existing structures.
- Keep `emergent_staging` private and unchanged until an separately approved transformation.
- Store money as non-negative integer paise and currency as ISO 4217.
- Put concurrency, state transitions and financial invariants in PostgreSQL RPCs.
- Use RLS for every user-visible table; grants alone are insufficient.
- Keep operational/private files in private Supabase Storage and approved public art media in Cloudinary/R2.

## Existing foundation

The development schema already contains 40 public tables, including artist onboarding, intermediary representation, artworks/media, auctions/proxy bidding, enquiries, sales, payment links, shipments, settlements, certificates, legal documents/acceptances, platform settings, taxonomies and audit events. Existing auction RPCs already provide the strongest part of the target architecture and must be preserved.

## Domain crosswalk and gaps

| Domain | Reuse | Additive gap | Do not create |
|---|---|---|---|
| Roles and permissions | `user_roles`, `profiles`, `tra_role` | Enum values `super_admin`, `finance`, `advisor`; `role_permissions`; `user_permission_overrides`; account status/last-seen metadata; permission helper functions | A second profiles/users table or app-managed passwords |
| Artist | `artist_profiles`, onboarding, documents, legal acceptances | Source/reference fields, practice year, participation, public reference; optional artist-taxonomy junction | Duplicate `artists` table |
| Intermediary relationships | `intermediary_profiles`, `artist_representations` and existing consent RPCs | Scope history/audit if individual scope changes need history; no replacement required | Emergent `representations` duplicate |
| Artwork | `artworks`, `artwork_media`, declarations, collections, taxonomies | Source fields, featured/view count; `artwork_taxonomies`; classification review evidence | Emergent `artworks` duplicate or URL arrays in one column |
| Auctions | `auctions`, `auction_lots`, bid request/event/proxy/watchlist/dispute/acceptance tables and hardened RPCs | Paused/version/estimate/premium snapshot/source fields; grouping decision for nine legacy lot documents | Mongo-style embedded bids/proxies; application-side bidding |
| Bidders | `bidder_eligibility`, auction acceptances | `bidder_profiles` for alias/contact snapshot | Role inferred from unverified email |
| Offers | None | `offers`, immutable `offer_events`, transactional submit/respond/expire RPC | Offers encoded in sales notes |
| Orders | Reuse `sales` as the commercial order aggregate | Order number/kind, buyer-user link, reservation expiry, source field; optional `sale_items` only if multi-item orders are approved | Parallel `orders` aggregate for the same sale |
| Payments | `payment_links`, sale payment status, settlements | `payment_events` and `ledger_entries`, webhook idempotency, provider reference indexes | Mutable balance columns or browser-writable payment state |
| Shipping | `shipments` | No core table; optional immutable shipment event history | Duplicate shipping table |
| Certificates | `certificates`, `certificate_files` | Source/reference fields, public verification token/hash, snapshot JSON, version/review events if required | Separate `cert_docs` domain |
| Legal | `legal_documents`, versions and acceptances | Audience array; draft metadata/title/change summary/material flag/creator reference; published-version immutability | Emergent legal tables |
| Art Journal | Extend `content_pages` | Content type, excerpt/category/cover/author/tags/SEO/editorial fields; `content_relations`, `journal_bookmarks`; publication workflow | Separate article body table unless scheduling/localisation later demands it |
| Notifications/email | None | `notifications`, `notification_preferences`, `notification_deliveries`; retry fields and indexes | Sending directly from database triggers |
| Analytics | None | Privacy-bounded `analytics_events` with visitor hash and retention policy | Raw IP, email or cross-site identifiers |
| Platform settings | `platform_settings` | Permissioned update RPC, schema/allow-list per key; no table replacement | Secrets in JSON settings; embedded `tscheck_*`/`v2test_*` keys |
| Audit | `audit_events` | Source/actor/entity text references for legacy imports; immutable insert path | Mutable Mongo audit-log clone |
| Media | `artwork_media`, certificate files, artist documents | Upload registry only if common lifecycle cannot be expressed by existing tables | Public identity documents/private originals |
| AI | None | Optional `ai_usage_events` only after AI approval; otherwise defer | Provider keys or prompts containing private documents in client code |

## Required changes by priority

### P0 security and identity

1. Extend role values without changing existing assignments.
2. Add permission tables and stable helper functions.
3. Add account status enforcement.
4. Harden last-Super-Admin, self-escalation and override rules.
5. Add identity-linking hold state; do not create `auth.users` from staging SQL.

### P1 data preservation

1. Add `source_record_id` where imported records require a stable reference.
2. Add normalized artwork-taxonomy and content-relation tables.
3. Extend `content_pages`, legal and audit structures.
4. Add analytics, notification and delivery structures.
5. Keep auctions, bidders, certificates and acceptances on hold until missing identity/legal relationships resolve.

### P2 transactional commerce

1. Add offers and append-only offer events.
2. Extend sales instead of creating competing orders.
3. Add payment events and immutable ledger entries.
4. Add reservation/offer/payment transactional RPCs and state-machine constraints.

## Constraints that must survive unchanged

- Existing artist and intermediary ownership policies and registration RPCs.
- Artist consent and administrator approval for representation.
- Published artwork/media gates.
- Auction eligibility, terms, database-time, proxy ceiling, idempotency, reserve and anti-sniping controls.
- Immutable legal acceptance evidence.
- Current Cloudflare/Supabase project separation.

## Gaps intentionally deferred

- Real-money auction enablement.
- Live payment credentials or reconciliation activation.
- Courier/insurance integrations.
- Production email provider selection.
- AI provider enablement and retention policy.
- Multi-item commercial orders.
- Production identity cutover.
- Production data migration or infrastructure changes.

## Risk findings

1. `tra_role` lacks `super_admin`, `finance` and `advisor`; current `admin` cannot safely stand in for all three.
2. The staging `users` and bidder use Clerk identifiers; they cannot become Supabase UUIDs without verified account linking.
3. The single certificate references an order not present in the 15-collection final staging set; it must remain on hold.
4. Nine auction documents do not carry the complete existing `auctions` parent requirements, including an approved terms version and creator; they require curated grouping.
5. Platform settings contain embedded QA-style legal-version keys even though the parent documents are genuine; those keys must be explicitly discarded.
6. Source audit actor/entity identifiers are text and cannot always become UUID foreign keys; additive reference fields are required.
7. Existing broad `admin_all` policies must not be copied to new finance/settings tables; named permissions are required.
