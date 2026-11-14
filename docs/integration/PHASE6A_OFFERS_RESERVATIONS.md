# Phase 6A offers, reservations, wishlist and bag

## Wishlist and recent views

The proposal stores one wishlist row per user/artwork and one recent-view row per user/artwork. RLS exposes only the active authenticated user's rows. The recent-view RPC upserts the timestamp/count and retains the latest 50 entries. Clearing affects only the caller. There is no anonymous or cross-user tracking.

## Shopping bag

One bag exists per user. Items snapshot the price observed when added, but the snapshot is informational: checkout must lock and re-read current publication, availability and price. Adding a unique artwork does not reserve it. Checkout remains blocked.

## Offer lifecycle

`submitted -> under_review -> sent_to_artist -> countered -> accepted/rejected/withdrawn/expired` is database-controlled. The RPC locks the offer and artwork, checks an expected state version, expiry, account state, buyer/seller/staff scope, current publication state and reservation conflict. Acceptance atomically creates a buyer if needed, creates a sale with an immutable price snapshot, converts the reservation, links the accepted sale, and appends an event.

Collectors can withdraw, accept or reject an active counteroffer on their side. An artist may act only on their own artwork. Administrative actions require `offers.manage`. Representation access remains dependent on the approved Phase 3 migration and scope vocabulary.

## Reservations

Creation takes an artwork-scoped advisory transaction lock, expires stale rows, revalidates publication, and relies on a partial unique index for a single pending/active reservation per artwork. A request lasts no more than seven days. Cancellation/release UI is preview-only until its final actor matrix is approved.

## Current status

All four domains have application contracts, disabled dashboard states, unit/integration coverage, and rehearsed SQL. Writes remain blocked because the proposal has not been applied and all flags default off. This is intentional and prevents a UI-only claim of persistence.

## Approval decisions

Approve offer minimums, default expiry, who may accept a counteroffer, administrator intervention, reservation duration/extension, whether accepted offers reserve immediately, buyer cancellation policy, tax jurisdiction, and intermediary authority. Acceptance must remain disabled until these rules and the Phase 3 representation functions are approved.

