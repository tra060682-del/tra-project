# tRA — The Real Art: master product requirements

## Product promise

tRA is a premium curated marketplace for original Indian art. It combines trusted discovery with human-assisted acquisition, artist and intermediary operations, authenticated evidence, carefully controlled publication and an optional auction channel. Phase 1 is not an automated checkout marketplace and does not activate real-money auction bidding.

## Personas and roles

| Role | Purpose | Security boundary |
|---|---|---|
| Public visitor | Discover published art, artists, collections and auctions; submit a consented enquiry | Public projections only; no private identities or operational records |
| Collector | Maintain a private profile/watchlist, accept auction terms and enquire or bid when eligible | Own records only; cannot gain staff roles |
| Artist | Complete onboarding, accept legal versions, submit owned work and track reviews/fulfilment | Own artist and artwork records only; cannot publish, price or approve |
| Intermediary | Apply for approval and request representation of consenting artists | Only approved relationships and explicitly delegated scopes; no bid/result control |
| Curator | Review artists/artworks and recommend classification or changes | No role assignment, publication, payment, settlement or final auction control |
| Admin | Approve identities, artworks, publication, enquiries and operations | Authenticated database permission; audited decisions; no direct bid manipulation |

`admin` remains the only privileged production enum value in the existing schema. Phase 1 adds narrowly scoped role values and RPC checks; no browser or signup metadata can assign privileged roles.

## Capability requirements

1. **Public website and discovery:** editorial homepage, searchable/filterable published catalogue, details, collections, artists, availability, accessible responsive presentation and safe fallbacks when inventory is absent.
2. **Artist onboarding:** verified email, artist-only role provisioning, profile drafts, immutable legal acceptance, submission, review remarks and status history.
3. **Intermediaries:** verified application, profile review, representation request, artist acceptance, admin approval, dated delegation scopes and revocation history.
4. **Curation:** review queues, change requests, taxonomy/classification recommendations and audit evidence. Only admins publish.
5. **Artwork inventory:** owned drafts, declarations, media metadata, review, final INR price, published/reserved/sold/unpublished states and one-active-sale protection.
6. **Auction Lobby:** public discovery, versioned terms, bidder eligibility, private maximums, row-locked bids, reserves, fair close and audit. Live bidding remains kill-switched.
7. **Collector accounts:** private profile, watchlist, enquiry and auction eligibility. Full account centre is Phase 2.
8. **Assisted commerce:** consented enquiry, assignment, notes, offer history and manual conversion. Offer workflow is Phase 2.
9. **Payments/orders/settlements:** manual link and evidence tracking, certificate/shipping/delivery and settlement states. Payment provider automation is Phase 2.
10. **Certificates:** artist evidence, admin verification, immutable versions and private sharing. UI and Storage integration are Phase 2.
11. **Advisory/commissions:** structured advisory requests and commissioned-work workflow are Phase 2.
12. **Content/analytics:** configurable support/legal/taxonomy/content, audit events and privacy-safe funnel analytics. CMS UI and analytics provider are Phase 2.

## API contracts for Phase 1

- `register_current_user_as_artist(display_name)` — verified account; assigns only artist.
- `register_current_user_as_intermediary(display_name, organisation)` — verified account; assigns only intermediary.
- `save_artist_onboarding(jsonb)` / `submit_artist_onboarding()` — owner-only draft and legal-gated submission.
- `save_intermediary_profile(jsonb)` / `submit_intermediary_profile()` — owner-only application.
- `request_artist_representation(artist_id, scopes, note)` — approved intermediary request; no automatic authority.
- `respond_to_representation(representation_id, accept)` — represented artist only.
- `submit_artist_artwork(jsonb)` — approved artist creates owned submission; publication fields ignored server-side.
- `review_artist_profile(...)`, `review_intermediary_profile(...)`, `review_artwork(...)` — curator recommendation/admin final decision, fully audited.
- `set_artwork_availability(artwork_id,status,remarks)` — admin-only controlled transition; rejects conflicting active sale/auction states.
- `tra_submit_enquiry(...)` — consent required, published artwork validation and no privileged client input.

All mutation endpoints validate again in PostgreSQL. Server actions are convenience adapters, not authorization boundaries.

## Core workflows and acceptance criteria

### Artist and artwork

Verified signup → artist role only → profile/legal draft → submit → curator review/change request → admin approval → artwork draft/declaration/media → review → admin price/publication. An artist cannot approve or publish; another artist cannot read or edit the record; every decision is auditable.

### Representation

Verified intermediary application → admin approval → intermediary requests named artist and limited scopes → artist accepts/rejects → admin approves → dated active relationship. No intermediary authority exists before both consent and admin approval; ended relationships remain historical.

### Assisted purchase

Visitor selects a published/available artwork → consents and enquires → admin triages/assigns → human contact and offer handling → manual payment link → confirmed sale → certificate/shipping/delivery/settlement. Phase 1 ends at secure enquiry and availability control.

### Auctions

Admin-approved artwork/terms/lot → bidder verification and acceptance → atomic bidding only when kill switch is explicitly enabled → controlled close → unpaid outcome requiring assisted operations. Phase 1 keeps the kill switch off.

## Non-functional requirements

- Supabase RLS on every private/operational table.
- Fixed search paths and restricted EXECUTE grants on security-definer functions.
- Integer paise for money; timestamps in UTC; immutable legal/bid/audit evidence.
- WCAG-conscious forms, keyboard navigation, descriptive media alternatives and responsive layouts.
- No production secrets, PII or database backups in Git/logs.
- Cloudflare development uses only `ocstvctvmychromkcurw`; production changes require separate approval.
