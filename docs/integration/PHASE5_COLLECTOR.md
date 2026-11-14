# Phase 5 Collector Account

`/account` provides a responsive Collector shell, self-profile and password-recovery links, identity-scoped enquiry history, identity-scoped sales/order history and the existing auction-lot watchlist. Reads use the authenticated user ID and current RLS.

The baseline has an auction watchlist but no general artwork-wishlist persistence, so “Saved artworks” is blocked rather than simulated. Offers/counteroffers, reservations, payments and notifications await additive contracts. Auction participation remains preview-only and cannot place real bids. Shipment presentation is withheld pending a collector-safe projection that excludes unnecessary private address data. Certificates remain disabled until a disclosure-safe authenticated RPC and private-file delivery mechanism are approved.

Anonymous enquiries created before identity linkage are not automatically claimed by matching an email address; that would require an approved verified-linking procedure.

