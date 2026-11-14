# Phase 4 visual and accessibility results

## Visual authority

The Phase 2 Emergent reference captures remain the signed visual authority. Phase 4 reuses their approved ivory/cream/near-black/antique-gold tokens, Lora/DM Sans/IBM Plex Mono typography, glass navigation, editorial spacing, art-led proportions, hairlines, restrained shadows and premium footer. No generic template or second token system was introduced.

## Captured acceptance views

| Surface | Viewport | Capture | Result |
|---|---:|---|---|
| Homepage | 1440 × 1000 | [home desktop](screenshots/phase4/home-desktop-1440.png) | PASS — approved hero, typography, four-column trust/works, pledge and footer preserved |
| Catalogue empty/data-safety state | 768 × 1024 | [catalogue tablet](screenshots/phase4/catalogue-tablet-768.png) | PASS — two-column filters, explicit zero-result state, no private/staged imagery |
| Art Advisory | 390 × 844 | [advisory mobile](screenshots/phase4/advisory-mobile-390.png) | PASS — artwork attribution, mobile navigation, honest disabled state and single-column footer |
| Auction Lobby | 1440 × 1000 | [auction desktop](screenshots/phase4/auctions-desktop-1440.png) | PASS — approved licensed image, preview warning and empty approved-lot state |

The screenshots were captured from the local Next.js runtime after the production build passed. The development environment intentionally had no Supabase browser configuration, so catalogue and form screenshots exercise the required safe empty/disabled states.

## Responsive results

The Phase 4 browser suite loaded all 13 principal public routes at 1440, 768 and 390 px. Every route satisfied:

- document scroll width ≤ client width + 1 px;
- no horizontal overflow;
- visible primary heading;
- no fabricated `Illustrative artist` content;
- stable single-column collapse at mobile width; and
- usable filter/form/empty-state layout.

Automated result: **42/42 browser tests passed** across the combined Phase 2, Phase 3 and Phase 4 suites.

## Accessibility checks

Passed automated/structural checks:

- semantic page headings and landmarks;
- skip link and keyboard-visible focus styling inherited from Phase 2;
- all public images have `alt` attributes;
- artwork credits remain visible and link to the licence source;
- enquiry inputs and textareas have associated labels;
- disabled operations are actually disabled, not merely hidden;
- status and error messages use live-region roles;
- native zoom dialog remains keyboard-dismissible;
- mobile navigation is keyboard operable; and
- colour tokens retain the Phase 2 WCAG 2.2 AA contrast decisions.

No full assistive-technology/manual screen-reader audit was performed in Phase 4. The browser run emitted performance suggestions to eager-load several above-the-fold licensed images; these are not accessibility failures and should be included in a later performance pass.

## Accepted differences from Emergent

1. Only rights-approved local imagery is used; unresolved Cloudinary, Unsplash and Emergent-hosted media remains quarantined.
2. No sample artwork or auction record is rendered as inventory.
3. Catalogue/artist/collection/journal surfaces show honest empty states until approved records exist.
4. Certificate lookup is disabled until database-level public disclosure controls are applied.
5. Forms store an approved enquiry record only; they do not claim email delivery.

