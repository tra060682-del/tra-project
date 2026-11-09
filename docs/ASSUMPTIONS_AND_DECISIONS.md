# Source of truth and scope decisions

1. The user confirmed that `tRA_Pilot_Documentation_Pack_v2.docx` is unavailable and authorised proceeding. The attached Claude prompt is the baseline; subsequent user instructions override it.
2. “curated” is interpreted as Curator; the stable role code is `curator`.
3. Staff/domain roles: super admin, admin, intermediary, artist, curator. Verified buyers are ordinary authenticated accounts with bidding eligibility, not a sixth staff role. A user may hold multiple domain roles.
4. Auctions and buyer bidding accounts override the original exclusions for auctions, bidding and buyer accounts. This does not authorise a cart, automated payment collection, automated payouts or buyer-room uploads.
5. India remains the launch market; INR and paise are used. Trade Me is a behavioural reference, not the platform identity, payment provider or jurisdiction.
6. Artists can be independent, or represented through dated intermediary associations. Many associations are structurally possible; one exclusive representative or multiple representatives must be established by commercial policy before launch. Private access is denied by default.
7. Intermediary commission rates are not invented. Association terms are snapshotted into an auction sale; taxes, platform commission, intermediary allocations and settlement need financial review before confirmation.
8. Curators review and recommend; admins control final pricing/publication; super admins control role and privileged settings management. The production UI for these permissions is still pending.
9. No seller, associated intermediary, curator, admin or super admin may bid on a conflicted lot. Admin/curator bidding is blocked globally in the foundation; stronger related-party detection remains a launch requirement.
10. Signed authenticity certificates are issued by artists. tRA coordinates and checks completeness.
11. Placeholder artwork is CSS illustration, visibly labelled. Real images and artist data require authorised uploads through Cloudinary.
12. No alternative hosting/database/payment service has been introduced. Delivery is source code prepared for Netlify; not a Sites deployment.
13. Reference rules reviewed 5 November 2026: Trade Me “Place a bid” and “Listing types”. Bids in final two minutes reset remaining time to two minutes. Highest eligible bid wins only when reserve is met. Proxy mechanics below/equal reserve use the full maximum; crossing reserve reaches at least reserve.
14. Buy Now, public questions and answers, bidder verification beyond email, deposits, buyer premiums, bid withdrawal, dispute/default windows and notifications need further design. No fee or auction legal obligation is invented.
