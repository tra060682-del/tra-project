# Catalogue parity review

Date: 2026-11-14  
Branch: `integration/emergent-catalogue-parity`  
Authority: Emergent `frontend/src/pages/Browse.tsx`, `components/gallery/ArtworkCard.tsx`, `components/gallery/Discovery.tsx`, executable browse tests, and the live `/browse` capture.

## Outcome

The Next.js catalogue now preserves the approved Emergent information hierarchy and interaction model without changing authentication, Supabase, RLS, Cloudflare, commerce, or staging data. The replacement “Art worth living with.” page has been removed.

Restored elements:

- “Browse original art” heading, supporting copy, editorial type scale, search placement, and 1400 px content frame.
- Painting, Printmaking, Digital Art, Drawing, Prints, Sculpture, Photography, and the complete More menu.
- Sticky desktop facet rail and accessible mobile filter drawer.
- Subject, Artform, Style, and Medium groups with collapse/expand, repeated-query multi-select, source-derived counts, show more/less, active chips, and clear actions.
- Emergent sort contract: curator order, recently added (`newest`), price ascending, price descending, and a visibly unavailable Most viewed option until an approved public view aggregate exists.
- Twelve-at-a-time load-more pagination matching the Emergent source.
- Three-column desktop, two-column tablet, and one-column mobile artwork gallery; 4:5 media, curator label, title, artist, style, and authorized INR price.
- Development fixture detail routes that are labelled as references and never expose an enquiry or purchase action.

## Security and content boundary

The normal `/artworks` route still queries only `public.artworks.status = published`, active taxonomy rows, approved public artist relationships, and approved artwork media. It never queries `emergent_staging`.

`/artworks?preview=approved-media` is an explicit visual-test mode. It is available only when `NODE_ENV !== production`, carries `noindex`, uses exactly the 26 files in the Phase 2 approved-media register, and labels every card “Development reference” and “Not inventory · not for sale.” The function returns no fixtures in production. The 23 quarantined files remain outside the public tree.

## Functional validation

The dedicated Playwright check executed 19 assertions covering heading, result count, initial pagination, load more, search, Artform single/multi-select, URL persistence, reset, category navigation, sorting, fixture detail, direct fixture denial without the preview gate, mobile drawer, and horizontal overflow. All 19 passed.

The wider regression suite passed:

| Suite | Result |
|---|---:|
| Unit | 106/106 passed |
| Integration | 59/59 passed |
| Security | 15/15 passed |
| Catalogue browser assertions | 19/19 passed |
| TypeScript / Next type generation | Passed |
| Next.js production build | Passed, 53 static-generation entries completed |
| Cloudflare compatibility | 100%, 0 issues |
| Cloudflare development environment validation | Passed with non-secret placeholder build inputs |

No ESLint result is claimed because ESLint is not configured. No database-level test was necessary or run because this change includes no SQL or database mutation.

## Files of interest

- `src/components/catalogue-browser.tsx` — interactive catalogue surface.
- `src/lib/catalogue-parity.ts` — source taxonomy, filtering, sorting, counts, and development fixture builder.
- `src/lib/catalogue.ts` — published-only Supabase projection with existing taxonomy relationships.
- `src/data/approved-media-register.ts` — exact 26-file rights-approved register used by fixture mode.
- `scripts/catalogue-parity-test.mjs` and `tests/catalogue-parity.test.mjs` — browser and invariant checks.

## Remaining differences

1. Live Emergent displays 33 demo works; public Supabase contains zero artwork rows. Production-safe Next.js therefore remains honestly empty until approved records exist.
2. The visual fixture has 26 references, not 33, because the other 23 export images are quarantined and cannot be used.
3. Fixture titles/credits come from the rights register and are intentionally not the Emergent demo identities, prices, or sale records.
4. Most viewed remains unavailable because no approved public analytics aggregate exists.
5. The global Next.js header/footer retain the Phase 2 implementation; catalogue-specific proportions are closely aligned, but the global shell is not pixel-identical to the Emergent shell.

No migration was applied, no staging record was promoted, no provider was enabled, and nothing was deployed.
