# Visual acceptance criteria

Status: Phase 1 design contract. No existing website styles, assets or components were modified.

## Authoritative references

- `C:\tra\tra-emergent\tra-emergent\design_guidelines.json`
- `frontend/src/index.css`
- `frontend/src/components/gallery/*`
- `frontend/src/components/dashboard/DashboardShell.tsx`
- `frontend/src/pages/Home.tsx`, `Browse.tsx`, `ArtworkDetail.tsx`, `Auctions.tsx`, `AuctionLot.tsx`
- `assets/IMAGE_MANIFEST.json` and the checksum-verified `assets/remote-images` archive

Source screens are behaviour/design references, not code to paste into the Next.js application.

## Design tokens

### Typography

| Use | Approved family | Required weights/style |
|---|---|---|
| Display, H1–H4, brand, curatorial quotes | Lora Variable | Regular, medium as needed, italic for editorial emphasis |
| Navigation, body, forms, tables | DM Sans Variable | Regular, medium, semibold |
| Lot numbers, dimensions, prices/countdowns | IBM Plex Mono | 400/500 |

Font assets must be self-hosted from npm packages; no render-blocking third-party font request. Fallbacks are Georgia/serif, system sans and ui-monospace respectively.

### Colour

| Token | Value | Use |
|---|---|---|
| Ivory page | `#FAF7F2` | Primary page background |
| Parchment | `#F5EFEB` | Secondary cards/panels |
| Panel | `#FFFFFF` | Forms, dialogs, tables |
| Ink | `#1C1A17` | Primary text/actions |
| Soft ink | `#635F59` | Secondary text |
| Gold | `#9E6B0E` | Links, eyebrow text, focus/accent |
| Gold border | `#DFCE9F` | Refined borders/highlights |
| Hairline | `#E7DFD5` | Separators/borders |
| Inverse | `#181614` | Dark editorial/auction surfaces |
| Error | `#B91C1C` | Destructive/validation states |
| Success | `#15803D` | Confirmed states |

Contrast acceptance: normal text ≥ 4.5:1; large text ≥ 3:1; focus indicators and meaningful non-text controls ≥ 3:1. Gold is not used for small body copy where contrast fails.

### Type scale and rhythm

- Display: 56 px desktop, fluid down to 42 px mobile.
- H1: 44 px target, fluid where the approved hero uses larger display text.
- H2: 32 px; H3: 24 px; H4: 20 px.
- Body: 16 px; caption: 14 px; micro-labels never below 11 px in the final accessible port.
- Base spacing uses a 4 px scale. Primary section gaps: 64–96 px desktop, 40–56 px mobile. Card gaps: 16–24 px. Hairline borders: 1 px.
- Corners remain restrained (approximately 4 px); artwork imagery is not presented with playful oversized rounding.

## Component inventory

| Component | Required states |
|---|---|
| Glass header/navigation | Desktop navigation, search, actions, sticky blur, mobile sheet/accordion, current page, keyboard navigation |
| Footer | Editorial links, legal, newsletter consent, social placeholders, mobile stacking |
| Artwork card | Approved image, alt text, artist/style/price, availability, wishlist, hover/focus zoom ≤ 1.02, missing-image fallback |
| Artwork gallery | Primary/detail images, thumbnail selection, zoom/inspection, keyboard operation, responsive containment |
| Filters | Desktop sidebar, mobile slide-out, multiselect, price bounds, counts, clear/reset, URL state |
| Auction card/lot | Demo/live/upcoming/past badges, INR values, monotonic countdown, reserve disclosure, disabled/eligible bid states |
| Forms | Label, help, required, invalid, submitting, success and server-error states; no placeholder-only labels |
| Dialog/sheet | Focus trap, Escape close, restored focus, labelled title/description, mobile full-height handling |
| Tabs/dashboard sidebar | URL-addressable active state, role switcher, permission-filtered items, mobile sheet, counts/badges |
| Tables | Responsive overflow or stacked alternative, header association, empty/loading/error states |
| Toast/status | Screen-reader announcement, non-destructive persistence where action is important |
| Certificate/QR | Printable verification surface; QR has text alternative and direct verification URL |
| Charts | Text/table equivalent, labelled units, no colour-only distinction |

## Approved imagery

- 49 image binaries are present and checksum-verified; total archive size is approximately 42.8 MB.
- Original URL, local path, SHA-256 and usage references are recorded in `IMAGE_MANIFEST.json`.
- Sources include Unsplash, Wikimedia, Cloudinary and Emergent-hosted files.
- No approved image may be replaced with a generated placeholder merely for convenience.
- Before public use, each image requires recorded rights/licence/credit, alt text, target owner, and approval state.
- Public delivery uses approved Cloudinary/R2 URLs and responsive variants; originals are not bundled into the Worker.
- Private customer/identity/certificate uploads are excluded from this archive and must not be made public.

## Layout acceptance

### Public site

1. Homepage retains the split editorial hero, heritage styles, featured works, auction spotlight, provenance promise and artist discovery hierarchy.
2. Browse retains filter clarity and an image-led grid/masonry feel without layout shift.
3. Artwork detail gives imagery visual priority and keeps provenance, dimensions, medium, period, certificate and enquiry actions legible.
4. Auctions retain the premium auction-house composition while clearly identifying demo/disabled real-money states.
5. Journal and legal pages use a readable editorial measure (approximately 65–75 characters).

### Five dashboard modes

The shared shell must support Super Admin, Admin/staff, Artist, Intermediary and Collector modes. Acceptance requires:

- Desktop persistent sidebar and mobile sheet.
- Role switcher only for roles/modes the signed-in account actually has.
- Permission-filtered modules; direct URL denial still enforced server-side.
- Page title, eyebrow, account context and sign-out always visible/reachable.
- Main content has no horizontal overflow at 390 px.
- Dense admin tables provide a usable mobile representation.
- Loading, empty, error and access-denied states match the premium visual system.

## Responsive baselines

| Viewport | Required checks |
|---|---|
| 1440 × 1000 | Full premium composition, max-width rhythm, dashboard sidebar, no excessive line length |
| 1280 × 800 | Header/navigation fit, three-column content where approved, tables usable |
| 1024 × 768 | Tablet transition, reduced grids, no clipped actions |
| 768 × 1024 | Tablet portrait, mobile navigation threshold, dialogs contained |
| 390 × 844 | Primary mobile golden baseline; no horizontal overflow; filter/dashboard sheets work |
| 360 × 800 | Minimum supported mobile stress test |

The source CSS uses major transitions near 1050 px and 700 px, with an additional 420 px narrow-mobile adjustment. The Next port may express equivalent breakpoints through Tailwind, but rendered behaviour must match.

## Visual regression suite

Golden screenshots are required for:

- Homepage: desktop and 390 px.
- Browse: default, filters open, populated results and empty results.
- Artwork detail: gallery, enquiry dialog and missing-image fallback.
- Auctions: lobby and lot, live/demo/closed states, bid disabled and eligible.
- Authentication: login, register, forgot/reset and validation error.
- Each of the five dashboard modes: overview plus one representative dense module.
- Legal article, Journal index/article and certificate verification.
- Access denied, not found, loading and server-error states.

Rules:

- Stable fixtures, fixed clock/timezone and deterministic animation state.
- Images awaited and fonts loaded before capture.
- Disable nonessential animation during snapshot capture.
- Pixel-diff thresholds are established per surface only after the approved golden is signed off; structural/overflow assertions always have zero tolerance.
- Add semantic assertions for headings, landmark order, focus, alt text and action labels; screenshots alone are insufficient.

## Interaction and motion

- Artwork hover scale ≤ 1.02 over approximately 300 ms ease-out.
- Auction-card lift ≤ 4 px.
- Dialog/sheet transitions use restrained fade/slide with backdrop blur.
- Respect `prefers-reduced-motion`; no required information depends on animation.
- Countdown, toast and carousel updates do not steal focus.

## Approval blockers

1. Formal rights/attribution decision for every archived image.
2. Golden screenshot sign-off for the approved Emergent design.
3. Decision whether dark theme is a product requirement; the approved default is light.
4. Final content/label review for dashboard modules and legal pages.
5. Confirmation of whether the legacy left brand rail in the current site remains or yields to the Emergent glass header.
