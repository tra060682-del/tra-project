# P0 public visual evidence

## Comparison method

The Emergent export remains authoritative. The live Emergent host was unavailable to automated access during the complete audit, so acceptance used:

1. `frontend/src/pages/Home.tsx`, `Browse.tsx`, `ArtworkDetail.tsx`, `Artists.tsx`, `Collections.tsx` and `components/gallery/SiteLayout.tsx` from the verified export;
2. approved Phase 2 Emergent homepage captures;
3. approved Emergent catalogue captures under `screenshots/parity-audit`;
4. fresh Next.js captures from the implementation branch.

This is source-and-reference comparison, not a claim of live pixel identity.

## Fresh screenshot matrix

All 15 captures are in [`screenshots/p0-public-parity`](screenshots/p0-public-parity).

| Surface | 1440px | 768px | 390px | Result |
|---|---|---|---|---|
| Homepage | [desktop](screenshots/p0-public-parity/home-desktop.png) | [tablet](screenshots/p0-public-parity/home-tablet.png) | [mobile](screenshots/p0-public-parity/home-mobile.png) | Source hero hierarchy and complete editorial order restored; mobile stack and footer verified. |
| Catalogue fixture | [desktop](screenshots/p0-public-parity/catalogue-desktop.png) | [tablet](screenshots/p0-public-parity/catalogue-tablet.png) | [mobile](screenshots/p0-public-parity/catalogue-mobile.png) | Three-column desktop gallery, 240px filter rail, categories, card ratios and mobile drawer preserved. |
| Artwork detail fixture | [desktop](screenshots/p0-public-parity/artwork-detail-desktop.png) | [tablet](screenshots/p0-public-parity/artwork-detail-tablet.png) | [mobile](screenshots/p0-public-parity/artwork-detail-mobile.png) | Two-column gallery/summary, narrative, related works and mobile stacking verified. |
| Artists fixture | [desktop](screenshots/p0-public-parity/artists-desktop.png) | [tablet](screenshots/p0-public-parity/artists-tablet.png) | [mobile](screenshots/p0-public-parity/artists-mobile.png) | Editorial heading, controls and portrait grid verified. |
| Collections fixture | [desktop](screenshots/p0-public-parity/collections-desktop.png) | [tablet](screenshots/p0-public-parity/collections-tablet.png) | [mobile](screenshots/p0-public-parity/collections-mobile.png) | Feature cover hierarchy, paired covers and mobile sequence verified. |

## Material acceptance observations

- Header is 64px, sticky, ivory/glass, and retains the source navigation order. Desktop dropdowns are keyboard-focusable; mobile navigation uses native nested disclosure controls.
- Hero uses approved public-domain art. The original Emergent hero asset was not substituted because it remains outside the approved 26-image boundary.
- Lora/DM Sans/IBM Plex Mono typography, ivory/near-black/antique-gold palette, section measure and editorial spacing are consistent with the source token system.
- Homepage sections now appear in the source order. Missing production content uses dimensional empty states; the page does not imply that records exist.
- Artwork images keep 4:5 catalogue proportions and contain-fit detail presentation. Mobile pages have no horizontal overflow.
- The development indicator visible in dev-server captures is framework tooling, not shipped application UI; production build validation passed.

## Evidence limits

- Production artwork, artist and collection pages cannot be populated until approved public records exist.
- Price alignment and real artist-to-artwork/collection relationships are validated structurally, not against production content.
- The 23 rights-unresolved assets cannot be used to reproduce original page imagery.
- Live Emergent screenshot comparison remains desirable once the host is accessible, but was not fabricated for this review.
