# P0 public remaining gaps

## Remaining P0 blockers

| Gap | Status | Blocker | Next approved action |
|---|---|---|---|
| VIS-005 / FUNC-009 production discovery | Partially resolved | No qualifying public artworks; source has 33 display records while the audited staging import is private | Approve a governed content-reconciliation exercise after schema/RLS approval. Do not promote staging wholesale. |
| DATA-001 artworks | Blocked | 27 staged artwork documents do not equal approved publishable inventory; relationships, statuses and media rights require review | Apply approved additive content contracts, reconcile field-by-field, rights-review each primary image, then publish explicitly. |
| DATA-002 artists | Blocked | Artist identities/profiles lack approved public consent and complete target relationships | Confirm identity matching, onboarding/legal acceptance and visibility consent before publication. |
| DATA-003 collections | Blocked | Collection-to-artwork relationships and publication state are not active in public data | Reconcile only after approved artworks exist and collection ordering is reviewed. |

## Remaining P1 public work

| Gap | Current state | Dependency |
|---|---|---|
| VIS-010 Auction lobby and lot | Secure preview exists but full source presentation is outside this workstream | Approved preview data; real bidding remains disabled. |
| VIS-011 Journal | Public shell exists; no approved articles | Content publication workflow and approved media. |
| VIS-012 Service pages | Safe enquiry routes exist but some source-specific modules remain generic | Approved intake contracts and content. |
| VIS-014 Authentication | Supabase flows work; Emergent visual shell is not yet fully matched | No database change required for visual work; preserve Supabase Auth. |
| MED-001–MED-023 | 23 source assets remain quarantined | Documentary rights approval or approved equivalent media from the rights holder. |

## Known limitations in this branch

- Fixture artist names describe historical heritage references and are explicitly not tRA accounts.
- Fixture collections are editorial groupings only; they are not database collections.
- Homepage featured heritage references are not listings, inventory or evidence of availability.
- Certificate verification, payment, offer acceptance, checkout, outbound email and live bidding remain disabled.
- Search/filter URL behaviour is active, but production result density remains data-dependent.

## Approval requests

1. Approve the next public workstream order: auction preview parity, Journal, service pages, then authentication presentation.
2. Decide whether a formal data-reconciliation rehearsal may proceed after additive schema/RLS approval.
3. Resolve or replace each of the 23 quarantined media assets through documented rights evidence.
4. Approve live Emergent access for a final side-by-side visual acceptance pass if the reference host becomes available.
