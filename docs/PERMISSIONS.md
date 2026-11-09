# Target permission matrix

| Capability | Super admin | Admin | Curator | Intermediary | Artist |
|---|---|---|---|---|---|
| Roles and privileged configuration | Manage | No | No | No | No |
| Artist approval and suspension | Manage | Manage | Recommend | No | Own request |
| Artist association approval | Manage | Manage | No | Request authorised link | Accept own link |
| Artwork submission | Oversight | Oversight | Review | Only explicit delegation | Own |
| Curation and change requests | Manage | Manage | Assigned review | Shared remarks | Own shared remarks |
| Final pricing and publication | Manage | Manage | Recommend | Propose only | Expected price only |
| Auctions and closing | Manage | Manage | Recommend lots | No | No |
| Payments and sales | Manage | Manage | No | Scoped status only | Scoped tasks only |
| Certificates and dispatch | Oversight | Manage | No | Explicit delegation only | Own |
| Settlement calculation | Manage | Manage | No | Own agreed entitlement view | Own view |
| Bidding | Blocked | Blocked | Blocked | Unrelated lots only | Unrelated lots only |

This is the design contract, not a claim that every screen or permission mutation is implemented. Foundation RLS allows only explicit read paths; delegated submission and settlements remain denied until their services are built. Auction buyers need verified email and accepted applicable terms, with no staff role required.
