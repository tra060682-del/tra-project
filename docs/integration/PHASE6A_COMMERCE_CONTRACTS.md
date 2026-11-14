# Phase 6A commerce contracts

## Shared application contracts

`src/lib/commerce/contracts.ts` validates UUID identity, ISO-style three-letter currency, safe integer minor units, statuses, notification categories, private-media purposes, feature names, and 256-bit URL-safe certificate token shape. Amount parsing rejects floating values, negative values, and values beyond JavaScript's safe integer range.

The domain helpers define:

- exact basis-point rounding and immutable order component snapshots;
- balanced debit/credit validation;
- explicit offer, order and shipment state transitions;
- deterministic reservation expiry;
- deduplicated communication preferences.

## Source-to-target API contract

| Emergent source | Target | Persistence contract | Activation |
|---|---|---|---|
| `GET/POST /api/me/wishlist...` (#49-50) | Collector RSC + `toggleWishlistAction` | `tra_toggle_wishlist` | migration + `TRA_FEATURE_WISHLIST` |
| `GET/POST/DELETE /api/cart...` (#44-46) | Collector RSC + `changeBagAction` | `tra_change_shopping_bag` | migration + `TRA_FEATURE_SHOPPING_BAG` |
| `POST /api/checkout` (#47) | typed totals only | future checkout RPC | Phase 6B approval |
| `POST/GET /api/offers...` (#53-55) | offer actions and scoped RSC reads | create/transition RPCs | migration + `TRA_FEATURE_OFFERS` |
| Admin/artist/intermediary offer lists (#41, #48, #59) | scoped dashboard projections | offer RLS | migration |
| Orders and shipping (#42-43, #56-58, #214) | baseline sale/shipment RSC reads | existing tables; future transition RPC | write approval |
| Payments (#144-149) | provider-neutral schema only | intents/events/ledger RPC | Phase 6B provider |
| Certificates (#185-187, #198) | gated issuer/admin UI and safe verifier contract | hashed-token RPC | migration + review |
| Notifications (#51-52) | read model + mark-read action | notification RLS/RPC | migration + flag |

## Server Action result

Mutations return a discriminated result: `{ok: true, data?}` or `{ok: false, code, message}`. Expected validation, disabled-feature, authentication, authorization, conflict, and database failures are represented without exposing provider payloads or database internals.

Every action performs this sequence independently: authenticate; require active account and permission/resource scope; require server feature flag; parse Zod input; call one RPC; return a bounded result. UI visibility is not authorization.

## Feature flags

Flags cover wishlist, recent views, offers, reservations, shopping bag, checkout, payments, refunds, settlements, certificate verification, notifications, outbound email, private media, courier integration and live auctions. They are read only on the server and default to false. A flag is necessary but never sufficient: database migration, permission enforcement, provider readiness and an approval record are also required.

