# Catalogue visual comparison

## Evidence set

Live reference captures were made from `https://the-real-art.emergent.host/browse`; Next.js captures were made from the explicit development fixture at `http://localhost:3000/artworks?preview=approved-media`. Both were captured on 2026-11-14 using Chromium with reduced motion.

| Width | Emergent reference | Next.js after correction | Structural result |
|---:|---|---|---|
| 1440 | [Emergent desktop](screenshots/parity-audit/catalogue-emergent-desktop-1440.png) | [Next.js desktop](screenshots/catalogue-parity/nextjs-desktop-1440.png) | 3 columns, 240 px facet rail, editorial header, category bar; no overflow |
| 768 | [Emergent tablet](screenshots/parity-audit/catalogue-emergent-tablet-768.png) | [Next.js tablet](screenshots/catalogue-parity/nextjs-tablet-768.png) | 2 columns, mobile filter control, horizontally scrollable category bar; no overflow |
| 390 | [Emergent mobile](screenshots/parity-audit/catalogue-emergent-mobile-390.png) | [Next.js mobile](screenshots/catalogue-parity/nextjs-mobile-390.png) | 1 column, full-width sort, drawer filter, 4:5 art; no overflow |

Machine-captured layout values:

| Viewport | Grid columns | Horizontal overflow |
|---|---|---:|
| 1440 | `324px 324px 324px` | 0 px |
| 768 | `329px 329px` | 0 px |
| 390 | `354px` | 0 px |

The raw measurements are in [capture-results.json](screenshots/catalogue-parity/capture-results.json).

## Material comparison

| Element | Before | Corrected | Assessment |
|---|---|---|---|
| Heading | “Art worth living with.” | “Browse original art” plus source copy | Equivalent |
| Category navigation | Missing | Seven primary categories plus More | Equivalent structure |
| Facets | Search/artist/budget form | Source Subject/Artform/Style/Medium rail | Equivalent structure and behavior |
| Gallery | Empty generic state | 3/2/1 responsive source proportions | Equivalent structure |
| Cards | Generic bordered cards | 4:5 image, curator flag, title/artist/style/price arrangement | Equivalent structure |
| Pagination | Missing | Source twelve-item Show more control | Equivalent |
| Mobile filtering | Missing | Modal left drawer with full facet controls | Equivalent behavior |
| Data | 0 public works | Still 0 public works; explicit 26-reference dev fixture | Intentionally different, security constrained |

## Acceptance result

All catalogue-specific Priority 0 structural criteria pass. Pixel-level identity is not claimed because the two evidence sets contain different authorized images and content, and the Next.js global header/footer differ from the Emergent shell. Meaningful comparison therefore used hierarchy, typography scale, spacing, facet width, column count, image ratio, controls, responsive transitions, and overflow rather than a misleading whole-page pixel percentage.

Outstanding visual work is limited to global-shell parity and real approved inventory content. The catalogue itself no longer introduces a redesign.
