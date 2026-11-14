# Phase 5 Admin

The Admin experience combines `/admin`, `/admin/marketplace`, `/admin/enquiries`, `/admin/auctions`, `/admin/content` and `/admin/finance`.

Artist, intermediary, artwork and representation review continue through the current security-definer RPCs. Artist consent precedes representation approval. Artwork publication remains subject to the existing price/media/commercial checks. Enquiries, content, legal records, sales and settlements are real authorised reads; assignment, internal-note mutation, editorial publication, payments and outbound delivery are not presented as successful.

Auction records and lots are read-only previews. Existing concurrency code is preserved, but all Phase 5 auction administration actions are held behind the closed live-auctions server gate. Real bidding, bidder approval, winner selection, closing, payment and settlement are unavailable.

Curators receive review/content modules only; Art Advisors receive enquiry modules; Finance / Operations receives reporting/audit modules. They do not inherit general Admin powers.

