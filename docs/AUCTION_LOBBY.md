# Auction Lobby

The Auction Lobby is an additive, development-tested module for curated tRA auctions. Public discovery is available at `/auctions`; real-money bidding is intentionally disabled by the `platform_settings.auction_real_money_bidding` kill switch.

## Architecture

- Supabase Auth supplies the authenticated bidder identity and verified-email evidence.
- `bidder_eligibility` records an explicit administrator decision.
- Existing `legal_document_versions` and immutable `legal_acceptances` preserve the exact accepted auction terms.
- `place_maximum_bid` is the only bid mutation path. It locks the lot row, validates time, eligibility, terms, conflicts, minimums and request idempotency, then resolves the proxy price atomically.
- Bidder maximums stay in `auction_proxy_bids` and are readable only by their owner. They are absent from public views and administrator screens.
- `auction_bid_requests` prevents duplicate request processing; `auction_bid_events` and existing `audit_events` preserve accepted activity.
- `close_auction` is administrator-only, row-locked and idempotent. A sold lot begins with `payment_status=not_requested`; no payment is collected automatically.
- Artist submissions are limited by existing artwork/artist ownership helpers. Artists cannot mutate bids, lots or outcomes.

## Development validation

Run `npm run test:auction-database` to create a disposable local Supabase stack, apply the production-compatible baseline plus the artist and auction migrations, run the verification SQL, race two synthetic bidders, replay an idempotency key, close the lot and inspect its audit evidence. The script stops and removes the local stack afterward. It never connects to production.

Run the hosted read-only checks after applying the migration to development:

```powershell
npx.cmd --yes supabase@latest db query --remote=ocstvctvmychromkcurw --read-only --file supabase/verify_auction_lobby_migration.sql
```

Every `critical_issues` value must be zero.

## Activation prerequisites

Do not change `auction_real_money_bidding` to `true` until all of the following are approved and tested:

1. Auction terms, privacy disclosures, bidder eligibility criteria, reserve disclosures and jurisdiction-specific legal review.
2. Identity/age checks, related-party conflict process, rate limiting, bot protection and operational monitoring.
3. Payment collection, buyer premium/tax decisions, failed-payment handling, refunds and reconciliation.
4. Cancellation, bid withdrawal, dispute, default and artwork-withdrawal procedures.
5. Certificate, condition report, provenance, shipping, insurance, delivery and settlement controls.
6. Production backup, migration rehearsal, explicit production approval and post-migration verification.
7. Approved original artwork media. Current illustrative studies are interface previews and are not auction inventory.

The migration must not be applied to production and the feature flag must not be enabled without a separate reviewed rollout approval.
