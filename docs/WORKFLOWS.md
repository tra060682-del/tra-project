# Workflows

## Auction target flow

Curated approved artwork → admin pricing/lot setup → scheduled lobby listing → verified bidder accepts versioned auction terms → server-validated manual/private maximum bid → reserve status and public bid update → two-minute extension if needed → server closing → sold if reserve met, otherwise unsold → assisted sale → manually verified payment → artist-signed certificate → artist-led dispatch → delivery → settlement.

Bidding supports private maximums with automatic price resolution against competing maximums. Equal maximums favour the earlier established maximum. Monetary values use integer paise. All accepted bid requests are idempotent per buyer/request UUID. Authenticated users cannot write proxy tables or price fields directly.

The foundation `close_auction` function must be triggered by an authorised admin. No unattended scheduler is implemented. Once the end time passes, the bid function refuses bids even if closing has not yet run. Closing creates exactly one sale for that auction and reserves the work; it does not mark payment paid. The complete commercial snapshot requires review.

## Artist representation

Artist may exist with zero intermediaries. Associations capture start/end dates, delegation flags and commercial terms. End an association rather than overwrite its historical terms. Approval, acceptance history and audited management services are next phase. Seller-related intermediaries are ineligible to bid on the associated work.

## Publication target flow

Artist draft → required legal acceptance → submission/declaration → curator review/change requests → admin approval and final price → publication. Artist prices never become public listing prices without administration. Future sales take immutable commission/representation snapshots.

## Remaining operational status families

Onboarding: draft/submitted/review/changes/approved/rejected/suspended. Certificate: not started/reference/template/awaiting artist/uploaded/check/changes/complete/shared. Shipping: pending/packaging/ready/dispatched/transit/delivered/exception/returned. Settlement: pending delivery/return window/ready/processing/settled/hold/dispute. Configurable database masters and transition services are not yet implemented.
