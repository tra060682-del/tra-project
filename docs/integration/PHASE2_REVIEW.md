# Phase 2 review — design system and media foundation

## Outcome

Phase 2 is complete on `integration/emergent-phase2-design`. The authoritative Emergent frontend was re-verified against `FILES.sha256` (388/388 entries matched), and its source tokens, typography, full-bleed editorial homepage, glass header, footer, media treatment, UI states, and dashboard patterns were adapted to Next.js without changing Supabase, authentication, RLS, auction, payment, onboarding, or Cloudflare configuration.

## Delivered

- Design tokens: ivory `#FAF7F2`, parchment `#F5EFEB`, ink `#1C1A17`, soft ink `#635F59`, antique gold `#9E6B0E`, soft gold `#DFCE9F`, hairline `#E7DFD5`, inverse `#181614`, success and error states, 4px radii, shadows, spacing, and responsive rules.
- Self-hosted fonts: Lora Variable, DM Sans Variable, and IBM Plex Mono.
- Reusable primitives: buttons, labelled inputs, select, textarea, checkbox, cards, badges, tabs, native dialogs/drawers, dropdowns, tables, pagination, notices, loading, empty, error, toast, and confirmation states.
- Navigation: responsive glass header and premium footer with working routes for Artworks, Artists, Collections, Auction Lobby, Art Advisory, For Artists, About, Contact, Account, Search, Wishlist, and Join as Artist.
- Media: responsive `next/image` component with object-fit control, credit, alt text, zoom, and responsive sizing. Twenty-six explicitly licensed export assets are local; 23 unresolved assets remain quarantined.
- Dashboard foundation: reusable sidebar, top bar, breadcrumbs, profile/notification controls, metrics, tables, filters, cards, and chart surface for Super Admin, Admin, Artist, Intermediary, and Collector. Existing role gates remain authoritative.
- Design preview: `/design-preview` is no-indexed and contains component and five-role dashboard acceptance surfaces only; it introduces no business workflow.
- Supporting public routes: `/artists`, `/collections`, and `/wishlist` prevent new header links from becoming dead ends. They are presentation-only and do not alter publishing or account logic.

## Visual comparison

Reference images were captured from a temporary copy of the verified Emergent source at 1440×1000, 768×1024, and 390×844. Runtime-only Clerk and backend providers were bypassed in that disposable copy and the source-declared homepage section order was supplied; no reference design markup or CSS was rewritten. Implementation images were captured from the Next.js production build at the same dimensions.

| Viewport | Emergent reference | Next.js implementation |
|---|---|---|
| 1440 desktop | [reference](screenshots/phase2/reference/emergent-home-desktop-1440.png) | [homepage](screenshots/phase2/implementation/home-desktop-1440.png) · [dashboard](screenshots/phase2/implementation/dashboard-desktop-1440.png) |
| 768 tablet | [reference](screenshots/phase2/reference/emergent-home-tablet-768.png) | [homepage](screenshots/phase2/implementation/home-tablet-768.png) · [dashboard](screenshots/phase2/implementation/dashboard-tablet-768.png) |
| 390 mobile | [reference](screenshots/phase2/reference/emergent-home-mobile-390.png) | [homepage](screenshots/phase2/implementation/home-mobile-390.png) · [dashboard](screenshots/phase2/implementation/dashboard-mobile-390.png) |

Accepted differences are intentional: locally licensed Wikimedia imagery replaces unresolved Emergent/Cloudinary/Unsplash media; the existing catalogue-preview safety banner remains; production Next.js navigation remains connected to working application routes; and source sections that require unimplemented Phase 3+ APIs are represented by foundation components rather than simulated business behaviour.

## Accessibility

- Skip link, visible focus rings, reduced-motion handling, semantic landmarks, labelled controls, alt text, table captions, live regions, and keyboard-operable tabs are present.
- Dialogs use the native modal API, support Escape, restore browser focus behaviour, and close on backdrop where applicable.
- Automated browser checks confirm accessible names for preview controls and no missing image `alt` attributes.
- Ink/ivory, muted/ivory, gold/ivory, and gold/inverse token pairs were reviewed against the WCAG 2.2 AA normal-text target; decorative low-contrast hairlines are not used to convey information alone.
- No horizontal overflow was found at 1440, 768, or 390 pixels across the homepage, catalogue, artists, collections, and design-preview routes.

## Validation results

| Check | Result |
|---|---|
| Emergent export checksums | PASS — 388/388 |
| TypeScript / Next type generation | PASS |
| Unit tests | PASS — 17/17 |
| Integration tests | PASS — 15/15 |
| Browser and Phase 2 accessibility tests | PASS — 22/22 |
| Next.js production build | PASS — 29 routes generated |
| Cloudflare development build | PASS |
| Database migrations applied | None |
| Production deployment or infrastructure mutation | None |

Cloudflare emits existing vinext/Rolldown sourcemap and dynamic-import warnings; the build completes successfully. The build used a non-secret placeholder publishable-key value solely to satisfy the existing environment guard during compilation.

## Remaining design discrepancies and decisions

1. The 23 media files without explicit export licence metadata are blocked from the publishable tree. Rights evidence is required before they can replace heritage references.
2. Contemporary artwork imagery must continue to enter through the existing approved `artwork_media` workflow; Phase 2 does not promote sample catalogue records.
3. Search currently submits to the existing catalogue query. Predictive cross-entity search waits for the Phase 1 API contracts to be implemented.
4. Wishlist and notification UI foundations are present, but persistence and role-aware notification data wait for later application phases.
5. The dashboard shell is visually complete as a foundation; role-specific information architecture and business actions remain deliberately unchanged.
6. Dark mode from the Emergent token file was not activated because the approved default is the ivory system and no product decision authorises a theme toggle.

## Phase 3 readiness

Ready for Phase 3 authentication and authorisation integration. Phase 3 should reuse these components while preserving the existing Supabase session and role checks, and should begin only after approval. No application-code or database-structure work beyond this visual foundation should proceed automatically.
