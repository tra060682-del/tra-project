# Phase 6A commerce architecture

## Outcome

Phase 6A adds a migration-ready commerce and operations slice without activating money movement, checkout, certificate verification, outbound delivery, courier integrations, or live auctions. The current 39-table development baseline remains the source of truth. Existing `artworks`, `buyers`, `sales`, `shipments`, `settlements`, `certificates`, and `payment_links` are extended by proposal rather than duplicated.

## Layers

1. `src/lib/commerce/contracts.ts` owns validated transport types and exact minor-unit fields.
2. `money.ts`, `state-machines.ts`, and `preferences.ts` contain deterministic domain rules with no presentation or provider coupling.
3. `features.ts` reads server-only flags. Missing configuration always means disabled.
4. `src/app/commerce/actions.ts` re-authenticates, checks account/permission state, checks a server flag, validates input, then invokes one narrowly scoped RPC.
5. The four commerce workspace routes integrate all five dashboard experiences: Super Admin and Admin share the operations module; Artist, Intermediary, and Collector have scoped projections.
6. `202611170101_phase6a_commerce.draft.sql` supplies transactional state changes, RLS, grants, immutable histories, and reconciliation structures.

No browser state is authoritative for price, availability, ownership, permission, reservation, payment, or ledger state. Provider callbacks and background delivery workers are deliberately absent.

## Data authority

| Domain | Existing authority | Proposed additive support |
|---|---|---|
| Catalogue | `artworks`, `artist_profiles` | Wishlist, recent views, bag |
| Order aggregate | `buyers`, `sales` | Offer and reservation references, immutable snapshots |
| Fulfilment | `shipments` | Shipment events and privacy-safe projections |
| Finance | `settlements`, `payment_links` | Intents, attempts, callbacks, refunds, append-only ledger, commissions |
| Authenticity | `certificates` | Hashed token, version, revocation and event history |
| Operations | Existing audit/RBAC functions | Notifications, private media audit, exceptions |

## Dashboard integration

- Collector Account: wishlist, recent views, bag, offers, orders, shipping, certificates, notifications.
- Artist Studio: offers, reservations, sales, fulfilment, certificate issuance and settlement visibility.
- Intermediary: only represented-artist offer, sale, commission and fulfilment projections.
- Admin: commerce queues, fulfilment, certificate review and exceptions.
- Super Admin: the Admin module plus provider/feature readiness and reconciliation controls.

Curators and Art Advisors do not receive a commerce navigation route. Finance / Operations may access the Admin commerce module through `reports.view`, but `auction.bid` remains explicitly denied.

## Non-negotiable boundaries

- No service-role credential is used for ordinary user work.
- All monetary amounts are integer minor units; no JavaScript floating-point amount is persisted.
- Original artwork reservation and offer acceptance use locked transactional RPCs.
- Ledger and provider events are append-only; corrections are compensating entries.
- Private media stores opaque keys, never public permanent URLs.
- The 26 approved heritage images remain public; no quarantined image was copied.
- Phase 6B must supply approved providers, workers, secrets, monitoring and incident procedures before activation.

