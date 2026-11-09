# Foundation tables

`user_roles`: five domain/staff roles. `artist_profiles`: private artist ownership. `artist_intermediaries`: optional dated association and terms snapshot. `artworks`: separate expected future submission pipeline, current listing foundation only. `auction_terms`, `auction_acceptances`: immutable version references for bidder eligibility. `auctions`: server-authoritative auction state, private reserve and leader. `proxy_bids`: bidder maximums and priority. `bid_requests`: idempotency results. `bid_events`: private bid history. `watchlists`: own-user watch records. `sales`: auction winner and commercial snapshot foundation. `audit_events`: append-only through trusted functions.

Public views: `public_artworks`, `public_auctions`. RPCs: `place_maximum_bid`, `close_auction`. UUID primary keys and integer paise. Active-auction partial unique index prevents overlapping active lots for a work; sale uniqueness prevents duplicate sales in this foundation. Cancellation/refund/resale workflows must replace that simple invariant before resale is introduced.

Full prompt domains including legal documents, submissions, enquiry notes, payment links, certificate files, shipments, settlements and master data are not yet migrated. This migration must not be treated as the complete product schema.
